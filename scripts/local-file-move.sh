#!/bin/bash

################################################################################
# TrueNAS Data Migration Script
# 
# Purpose: Safely migrate large media files between ZFS pools using rsync
# Author: System Administrator
# Version: 1.0
# Date: $(date +%Y-%m-%d)
#
# Features:
# - Resumable transfers with progress monitoring
# - Integrity verification via size comparison
# - Proper permission handling for media files
# - Time estimates and transfer statistics
# - Configurable source/destination paths
# - Comprehensive logging
#
# Usage: ./local-file-move.sh [--dry-run] [--verify-only]
#
# Tips: run in screen with 'screen -S <session_name>'
#
# Example: screen -S media-migration
# Tips: use Ctrl+A, D to detach
# 
# To reattach to your screen session later, use:
#   screen -r <session_name>
# For example, if you started with 'screen -S media-migration', reattach with:
#   screen -r media-migration
#
################################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration Variables - Modify these for different transfers
SOURCE_BASE="/mnt/Media/media"
DEST_BASE="/mnt/tank/media/data/media"
LOG_FILE="/tmp/rsync-transfer-$(date +%Y%m%d_%H%M%S).log"
VERIFY_LOG="/tmp/verify-$(date +%Y%m%d_%H%M%S).log"

# Media subdirectories to transfer
declare -a MEDIA_DIRS=("tv_shows:tv" "movies:movies")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Utility Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    --dry-run       Show what would be transferred without actually copying
    --verify-only   Only run verification, skip transfer
    --help          Show this help message

EXAMPLES:
    $0                    # Run full transfer
    $0 --dry-run         # Test run without copying
    $0 --verify-only     # Only verify existing transfers

CONFIGURATION:
    Source: $SOURCE_BASE
    Destination: $DEST_BASE
    
    Media directories to transfer:
$(for dir_pair in "${MEDIA_DIRS[@]}"; do
    src_dir="${dir_pair%:*}"
    dst_dir="${dir_pair#*:}"
    echo "      $src_dir -> $dst_dir"
done)

EOF
}

human_readable_size() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [[ $bytes -ge 1024 && $unit -lt 4 ]]; do
        bytes=$((bytes / 1024))
        ((unit++))
    done
    
    echo "${bytes}${units[$unit]}"
}

################################################################################
# Pre-flight Checks
################################################################################

check_prerequisites() {
    log "Starting pre-flight checks..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root to handle permissions correctly"
    fi
    
    # Check if required commands exist
    for cmd in rsync du df zfs; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Required command '$cmd' not found"
        fi
    done
    
    # Check source directories exist
    for dir_pair in "${MEDIA_DIRS[@]}"; do
        src_dir="${dir_pair%:*}"
        if [[ ! -d "$SOURCE_BASE/$src_dir" ]]; then
            error "Source directory does not exist: $SOURCE_BASE/$src_dir"
        fi
    done
    
    # Check destination base exists
    if [[ ! -d "$DEST_BASE" ]]; then
        error "Destination base directory does not exist: $DEST_BASE"
    fi
    
    # Check available space
    local source_size=$(du -sb "$SOURCE_BASE" | cut -f1)
    local dest_available=$(df -B1 "$DEST_BASE" | tail -1 | awk '{print $4}')
    
    if [[ $source_size -gt $dest_available ]]; then
        error "Insufficient space. Need: $(human_readable_size $source_size), Available: $(human_readable_size $dest_available)"
    fi
    
    log "✓ All pre-flight checks passed"
    log "  Source size: $(human_readable_size $source_size)"
    log "  Available space: $(human_readable_size $dest_available)"
}

warn_about_snapshot() {
    cat << EOF

${YELLOW}⚠️  IMPORTANT: CREATE SNAPSHOTS BEFORE PROCEEDING ⚠️${NC}

Before running this migration, create ZFS snapshots of your source data:

    zfs snapshot Media@pre-migration-\$(date +%Y%m%d)
    zfs snapshot tank@pre-migration-\$(date +%Y%m%d)

This provides a safety net in case of any issues during transfer.

EOF
    
    read -p "Have you created snapshots? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warn "Proceeding without snapshots - not recommended for production data"
        read -p "Continue anyway? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Transfer cancelled by user"
            exit 0
        fi
    fi
}

################################################################################
# Transfer Functions
################################################################################

transfer_directory() {
    local src_dir="$1"
    local dst_dir="$2"
    local dry_run="$3"
    
    local source_path="$SOURCE_BASE/$src_dir"
    local dest_path="$DEST_BASE/$dst_dir"
    
    log "Starting transfer: $src_dir -> $dst_dir"
    
    # Create destination directory if it doesn't exist
    if [[ "$dry_run" != "true" ]]; then
        mkdir -p "$dest_path"
    fi
    
    # Build rsync command
    local rsync_opts=(
        --archive                    # Preserve permissions, times, etc.
        --verbose                   # Verbose output
        --human-readable           # Human readable sizes
        --progress                 # Show progress
        --partial                  # Keep partial files (resumable)
        --inplace                  # Update files in-place (faster for large files)
        --stats                    # Show transfer statistics
        --itemize-changes          # Show what's being transferred
        --log-file="$LOG_FILE"     # Log to file
        --chmod=755               # Set directory permissions
        --chmod=644               # Set file permissions
    )
    
    if [[ "$dry_run" == "true" ]]; then
        rsync_opts+=(--dry-run)
        log "DRY RUN: Would transfer from $source_path/ to $dest_path/"
    fi
    
    # Execute rsync with progress monitoring
    log "Executing: rsync ${rsync_opts[*]} '$source_path/' '$dest_path/'"
    
    if rsync "${rsync_opts[@]}" "$source_path/" "$dest_path/"; then
        log "✓ Transfer completed successfully: $src_dir -> $dst_dir"
    else
        error "Transfer failed for: $src_dir -> $dst_dir"
    fi
}

################################################################################
# Verification Functions
################################################################################

verify_transfer() {
    local src_dir="$1"
    local dst_dir="$2"
    
    local source_path="$SOURCE_BASE/$src_dir"
    local dest_path="$DEST_BASE/$dst_dir"
    
    log "Verifying transfer: $src_dir -> $dst_dir"
    
    # Compare directory sizes
    local src_size=$(du -sb "$source_path" 2>/dev/null | cut -f1 || echo "0")
    local dst_size=$(du -sb "$dest_path" 2>/dev/null | cut -f1 || echo "0")
    
    # Compare file counts
    local src_count=$(find "$source_path" -type f 2>/dev/null | wc -l || echo "0")
    local dst_count=$(find "$dest_path" -type f 2>/dev/null | wc -l || echo "0")
    
    # Log verification results
    {
        echo "=== Verification Results for $src_dir -> $dst_dir ==="
        echo "Source size: $(human_readable_size $src_size) ($src_size bytes)"
        echo "Destination size: $(human_readable_size $dst_size) ($dst_size bytes)"
        echo "Source files: $src_count"
        echo "Destination files: $dst_count"
        echo "Size difference: $((dst_size - src_size)) bytes"
        echo "File count difference: $((dst_count - src_count))"
        echo ""
    } | tee -a "$VERIFY_LOG"
    
    # Check for exact match
    if [[ "$src_size" -eq "$dst_size" && "$src_count" -eq "$dst_count" ]]; then
        log "✓ Verification PASSED: Sizes and file counts match exactly"
        return 0
    elif [[ "$dst_size" -ge "$src_size" && "$dst_count" -ge "$src_count" ]]; then
        warn "Verification WARNING: Destination has more data (possibly resume artifacts)"
        return 1
    else
        error "Verification FAILED: Data mismatch detected"
        return 2
    fi
}

run_comprehensive_verification() {
    log "Running comprehensive verification..."
    
    local all_passed=true
    
    for dir_pair in "${MEDIA_DIRS[@]}"; do
        src_dir="${dir_pair%:*}"
        dst_dir="${dir_pair#*:}"
        
        if ! verify_transfer "$src_dir" "$dst_dir"; then
            all_passed=false
        fi
    done
    
    if [[ "$all_passed" == "true" ]]; then
        log "✓ All transfers verified successfully"
    else
        warn "Some transfers have verification issues - check logs"
    fi
    
    log "Detailed verification log: $VERIFY_LOG"
}

################################################################################
# Main Execution
################################################################################

main() {
    local dry_run=false
    local verify_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --verify-only)
                verify_only=true
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    # Print header
    cat << EOF

${BLUE}================================================================================
TrueNAS Media Migration Script
================================================================================${NC}

Configuration:
  Source: $SOURCE_BASE
  Destination: $DEST_BASE
  Log file: $LOG_FILE
  Verify log: $VERIFY_LOG
  Dry run: $dry_run
  Verify only: $verify_only

Media directories:
$(for dir_pair in "${MEDIA_DIRS[@]}"; do
    src_dir="${dir_pair%:*}"
    dst_dir="${dir_pair#*:}"
    printf "  %-15s -> %s\n" "$src_dir" "$dst_dir"
done)

${BLUE}================================================================================${NC}

EOF

    # Initialize log file
    log "Starting TrueNAS media migration script"
    log "Command: $0 $*"
    
    # Run checks
    check_prerequisites
    
    if [[ "$verify_only" != "true" ]]; then
        warn_about_snapshot
        
        # Perform transfers
        log "Starting data transfer phase..."
        local start_time=$(date +%s)
        
        for dir_pair in "${MEDIA_DIRS[@]}"; do
            src_dir="${dir_pair%:*}"
            dst_dir="${dir_pair#*:}"
            transfer_directory "$src_dir" "$dst_dir" "$dry_run"
        done
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "Transfer phase completed in ${duration} seconds ($(date -u -d @${duration} +%H:%M:%S))"
    fi
    
    # Run verification unless it's a dry run
    if [[ "$dry_run" != "true" ]]; then
        run_comprehensive_verification
    fi
    
    log "Script execution completed"
    log "Logs available at: $LOG_FILE"
    
    if [[ "$dry_run" != "true" ]]; then
        log "Verification results: $VERIFY_LOG"
        
        cat << EOF

${GREEN}===============================================================================
Migration Summary
===============================================================================${NC}

Next steps:
1. Review the verification log: $VERIFY_LOG
2. Test access to migrated media files
3. Update any applications pointing to old paths
4. Consider removing old data after thorough testing

Paths updated:
$(for dir_pair in "${MEDIA_DIRS[@]}"; do
    src_dir="${dir_pair%:*}"
    dst_dir="${dir_pair#*:}"
    echo "  $SOURCE_BASE/$src_dir -> $DEST_BASE/$dst_dir"
done)

${GREEN}===============================================================================${NC}

EOF
    fi
}

# Execute main function with all arguments
main "$@"
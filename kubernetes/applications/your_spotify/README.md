# YourSpotify

YourSpotify is a self-hosted application that tracks what you listen and offers you a dashboard to explore statistics about it!

## Prerequisites

1. **Create a Spotify Application**:
   - Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/applications)
   - Click "Create app"
   - Fill out the information
   - Set the redirect URI to: `https://your-spotify.ghart.space/api/oauth/spotify/callback`
   - Check "Web API"
   - Copy the Client ID and Client Secret

2. **Update the secrets file**:
   - Edit `your-spotify-secrets.yaml`
   - Replace `__your_spotify_client_id__` with your Spotify Client ID
   - Replace `__your_spotify_secret__` with your Spotify Client Secret

## Deployment Steps

1. **Apply the secrets first**:
   ```bash
   kubectl apply -f your-spotify-secrets.yaml
   ```

2. **Deploy the application**:
   ```bash
   kubectl apply -f .
   ```

3. **Access the application**:
   - Navigate to `https://your-spotify.ghart.space`
   - Log in with your Spotify account
   - Start tracking your music!

## Components

- **YourSpotify App**: LinuxServer.io image with both client and server
- **MongoDB**: Database for storing listening history
- **Longhorn Storage**: Persistent storage with retain policy
- **Traefik Ingress**: HTTPS access with TLS

## Notes

- The application polls Spotify API every few minutes to track your listening
- You can import historical data from Spotify's privacy data export
- Only users registered in the Spotify app dashboard can use the application (unless you request extension)
- Initial setup may take a few minutes for the database to initialize

A self hosted spotify dashboard: https://github.com/Yooooomi/your_spotify
# KAFKA
Kafka is a message queue system which works really well as a pub/sub system and also as a logger. Its open source from the apache foundation. Its super powerful and used by lots of big companies for everything from tracking fleets of car telementry data to storing and acheiving the new york times articles.

I'm using kafka to stream telemetry from my car.

# Quick testing
Exec into the pod and you can use these commands to test.
`/bin/kafka-topics --create --topic topic-name --bootstrap-server localhost:9092`
`/bin/kafka-console-consumer --topic topic-name --from-beginning --bootstrap-server localhost:9092`
`/bin/kafka-console-producer --topic topic-name --bootstrap-server localhost:9092 `
Note: do this from another shell

# portainer mount
Had to put a portainer relative mount with the path `/home/garrett/portainer-compose-unpacker`

#! /bin/bash

########################### This part is used to copy properties file out ##########################
sudo docker build ./messaging/kafka/ -t aimvector/kafka:2.7.0
#docker run --rm --name kafka -it aimvector/kafka:2.7.0 bash
docker run -d --rm --name kafka aimvector/kafka:2.7.0

docker exec -it kafka bash -c "ls -l /kafka/bin"

# ls -l /kafka/bin
# ls -l /kafka/config
# cat /kafka/config/server.properties ## Basic configuration for Kafka

docker cp kafka:/kafka/config/zookeeper.properties ~/docker-development-youtube-series/messaging/kafka/zookeeper.properties
docker cp kafka:/kafka/config/server.properties ~/docker-development-youtube-series/messaging/kafka/server.properties

## Let's create a kafka network and run 1 zookeeper instance
sudo docker build ./messaging/kafka/zookeeper -t aimvector/zookeeper:2.7.0
docker network create kafka

docker run -d --rm --name zookeeper-1 --net kafka \
-v ~/docker-development-youtube-series/messaging/kafka/config/zookeeper-1/zookeeper.properties:/kafka/config/zookeeper.properties \
aimvector/zookeeper:2.7.0

docker logs zookeeper-1

docker run -d --rm --name kafka-1 --net kafka \
-v ~/docker-development-youtube-series/messaging/kafka/config/kafka-1/server.properties:/kafka/config/server.properties \
aimvector/kafka:2.7.0

docker run -d --rm --name kafka-2 --net kafka \
-v ~/docker-development-youtube-series/messaging/kafka/config/kafka-2/server.properties:/kafka/config/server.properties \
aimvector/kafka:2.7.0

docker run -d --rm --name kafka-3 --net kafka \
-v ~/docker-development-youtube-series/messaging/kafka/config/kafka-3/server.properties:/kafka/config/server.properties \
aimvector/kafka:2.7.0

docker exec -it zookeeper-1 bash -c \
"/kafka/bin/kafka-topics.sh \
--create \
--zookeeper zookeeper-1:2181 \
--replication-factor 1 \
--partitions 3 \
--topic Orders"

docker exec -it zookeeper-1 bash -c \
"/kafka/bin/kafka-topics.sh \
--describe \
--topic Orders \
--zookeeper zookeeper-1:2181"

docker exec -it zookeeper-1 bash -c \
"/kafka/bin/kafka-console-consumer.sh \
--bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 \
--topic Orders --from-beginning"

for i in {1..100}; do
docker exec -it zookeeper-1 bash -c \
"echo \"New Order: $i\" | \
/kafka/bin/kafka-console-producer.sh \
--broker-list kafka-1:9092,kafka-2:9092,kafka-3:9092 \
--topic Orders > /dev/null";
#sleep 1;
done


docker exec -it kafka-3 bash -c "apt install -y tree"
docker exec -it kafka-3 bash -c "tree /tmp/kafka-logs/"
docker exec -it kafka-1 bash -c "ls -lh /tmp/kafka-logs/Orders-0"
docker exec -it kafka-3 bash -c "ls -lh /tmp/kafka-logs/Orders-1"
docker exec -it kafka-1 bash -c "ls -lh /tmp/kafka-logs/Orders-2"

docker exec -it zookeeper-1 bash -c \
"cat /kafka/bin/kafka-console-producer.sh"
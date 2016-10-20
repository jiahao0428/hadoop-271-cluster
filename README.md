# Apache Hadoop/Yarn 2.7.1 cluster Docker image
This project is actually a clone from https://github.com/sfedyakov/hadoop-271-cluster with some small usability enhancements and some to let the image work in Docker Machine/Compose Swarm clusters and use Spark. The essence of the latter enhancements is to copy entries from /etc/hosts to nodes across the cluster, because Docker Compose has some bugs with DNS and host aliases.

# Build the image
Before you build, please download the following: Oracle Java and Apache Hadoop.


# Limitations
Please be aware of the following
- You have to download each installing packages (hadoop, spark, elasticsearch, kibana) 
- Exactly one Namenode is allowed
- /etc/hosts are synchronized continuously every 60 seconds. So if you add more nodes during cluster run, new nodes may not be visible to existing ones for about a minute. Hope, Docker will fix their Compose DNS issues!

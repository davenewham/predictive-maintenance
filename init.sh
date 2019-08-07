#!/usr/bin/env bash
###############################################################################
# This script installs Spark, OpenTSDB, and Grafana in the MapR developer
# sandbox container so the sample applications in the Predictive Maintenance
# tutorial can run.
###############################################################################

# Reduce memory usage required by the sandbox
sudo yum remove mapr-hive mapr-spark -y
sudo yum install maven git screen jq -y

# Install Spark and Kafka
sudo yum install mapr-spark mapr-spark-master mapr-spark-historyserver mapr-spark-thriftserver mapr-kafka -y
cp /opt/mapr/spark/spark-2.3.1/conf/slaves.template /opt/mapr/spark/spark-2.3.1/conf/slaves
sudo /opt/mapr/server/configure.sh -R

# Set the local timezone so Grafana timestamps
#sudo yum --download-only install tzdata
#sudo dpkg -i  /var/cache/apt/archives/tzdata*.deb
#sudo rm /etc/localtime
#sudo ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

# Install OpenTSDB and Grafana:
sudo yum install mapr-opentsdb -y
sudo yum install mapr-grafana -y

# Enabled write access to opentsdb
sudo echo "tsd.http.request.cors_domains=*" >> /opt/mapr/opentsdb/opentsdb-2.4.0/etc/opentsdb/opentsdb.conf 
sudo echo "tsd.core.meta.enable_tsuid_incrementing = true" >> /opt/mapr/opentsdb/opentsdb-2.4.0/etc/opentsdb/opentsdb.conf 
sudo cat /opt/mapr/opentsdb/opentsdb-2.4.0/etc/opentsdb/opentsdb.conf | sed "s/#tsd.mode = ro/tsd.mode = rw/g" > /opt/mapr/opentsdb/opentsdb-2.4.0/etc/opentsdb/opentsdb.conf.new
sudo mv /opt/mapr/opentsdb/opentsdb-2.4.0/etc/opentsdb/opentsdb.conf.new /opt/mapr/opentsdb/opentsdb-2.4.0/etc/opentsdb/opentsdb.conf
sudo chown mapr:mapr /opt/mapr/opentsdb/opentsdb-2.4.0/etc/opentsdb/opentsdb.conf

# Start OpenTSDB and Grafana:
sudo /opt/mapr/server/configure.sh -R -OT `hostname -f`
sudo /opt/mapr/opentsdb/opentsdb-2.4.0/etc/init.d/opentsdb start

# Download and compile the tutorial code
git clone https://github.com/mapr-demos/predictive-maintenance
cd predictive-maintenance/sample_dataset
gunzip mqtt.json.gz
cd ..
mvn package

# Create the necessary streams
maprcli stream create -path /apps/factory -produceperm p -consumeperm p -topicperm p -ttl 900 -json
maprcli stream topic create -path /apps/factory -topic mqtt -partitions 1 -json
maprcli stream topic create -path /apps/factory -topic failures -partitions 1 -json
maprcli stream create -path /apps/fastdata -produceperm p -consumeperm p -topicperm p -ttl 900 -json
maprcli stream topic create -path /apps/fastdata -topic vibrations -partitions 1 -json

FROM ubuntu:14.04

MAINTAINER pamtrak06 <pamtrak06@gmail.com>

# Configuration for postgres installation
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt trusty-pgdg main" >> /etc/apt/sources.list'
RUN apt-get -y install wget
RUN wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
RUN apt-get update

# Configure system
RUN locale-gen --no-purge en_US.UTF-8
ENV LC_ALL en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

# Install postgres/posgis
RUN apt-get install postgresql-9.4-postgis-2.1 pgadmin3 postgresql-contrib

# Configure postgres
RUN echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/9.4/main/pg_hba.conf
RUN service postgresql start && /bin/su postgres -c "createuser -d -s -r -l docker" && /bin/su postgres -c "psql postgres -c \"ALTER USER docker WITH ENCRYPTED PASSWORD 'docker'\"" && service postgresql stop
RUN echo "listen_addresses = '*'" >> /etc/postgresql/9.3/main/postgresql.conf
RUN echo "port = 5432" >> /etc/postgresql/9.3/main/postgresql.conf

# Install pgrouting
#RUN apt-add-repository -y ppa:georepublic/pgrouting
#RUN apt-get update
#RUN apt-get install postgresql-9.4-pgrouting

# Install compilation prerequisites
RUN apt-get install -y software-properties-common g++ make cmake git

# Install pgrouting
RUN git clone https://github.com/pgRouting/pgrouting.git
RUN cd pgrouting; mkdir build; cd build; cmake -DWITH_DD=ON ..; make; make install

# Create a database example with pgrouting activated
RUN /bin/su postgres -c "createdb gis_database"
RUN /bin/su postgres -c "psql gis_database -c \"create extension postgis\""
RUN /bin/su postgres -c "psql gis_database -c \"create extension postgis_topology\""
RUN /bin/su postgres -c "psql gis_database -c \"create extension postgis_tiger_geocoder\""
RUN /bin/su postgres -c "psql gis_database -c \"create extension fuzzystrmatch\""
RUN /bin/su postgres -c "psql gis_database -c \"create extension pgrouting\""

# Enable Adminpack
RUN /bin/su postgres -c "psql postgres -c \"create extension adminpack\""

# Install osm2pgrouting
RUN git clone https://github.com/pgRouting/osm2pgrouting.git
RUN cd osm2pgrouting; cmake -H. -Bbuild; cd build/; make; make install

# Remove unused at runtime
RUN apt-get remove software-properties-common g++ make cmake git



# PGADMIN4 Framework

pgAdmin4 is the leading open-source graphical administration and development platform for PostgreSQL, offering a user-friendly interface (web-based or desktop) for managing databases, writing queries, monitoring, and performing daily database tasks, suitable for both beginners and experts, featuring query tools, schema management, and data viewing, built with Python/Flask and ReactJS. 

# Why do we need it

On AIE software stack today using EzPresto you can:
 - create tables
 - insert into tables

EzPresto does not support
 - create schemas
 - drop tables
 - update tables
 - delete from tables

Using the PGADMIN4 you can literally do anything with full permissions using a UI.

# Pre-requistes to use this

You should have Postgresql deployed and know the IP/Servic Endpoint, port, username and password to connect. 

In the values.yaml below is where you can define the server details.
You can choose not to define too. 

```
  # Inline server definitions (ignore if you point to an existing resource)
  # You can use Helm templates here, e.g. Host: "{{ .Values.example.host }}"
  servers:
    firstServer:
      Name: "Minimally Defined Server"
      Group: "Servers"
      Username: "postgres"
      Host: "postgresql.postgresql.svc.cluster.local"
      Port: "5432"
      SSLMode: "prefer"
      MaintenanceDB: "postgres"
```



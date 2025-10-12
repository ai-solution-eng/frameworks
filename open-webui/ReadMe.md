Open WebUI

When you plan to have a lot of users (talking like more than 10) and several documents in there, consider either using an external database and link it (values.yaml databaseUrl line 338) or bumping up the default value of Persistence from 2Gi to something larger (values.yaml line 226). If you don't do that you might hit weird error messages in the pod logs regarding the sqlite.  

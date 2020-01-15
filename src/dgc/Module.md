This module provides and interface to the Collibra Data Governance platform
[//]: # (above is the module summary)

# Module Overview
This module consist of three distinct components
- Assettypes: These are abstractions of assettypes related to the ingestion of technical metadata
- Client: This component takes care of connecting to the Collibra DGC API
- JdbcJsonFactory: This component connects to a database using JDBC and uses the queries in the configuration to extract metadata from the database and build a JSON object from this. 

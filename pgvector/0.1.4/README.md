# pgvector Framework for PostgreSQL 18

**Framework version:** 0.1.4  
**PostgreSQL version:** 18

## Overview

The **pgvector Framework** provides a PostgreSQL 18 deployment with the **pgvector** extension pre-configured, enabling vector similarity search directly within PostgreSQL.

It is designed for AI and Retrieval-Augmented Generation (RAG) workloads where embeddings and structured application data can be stored and queried from the same database.

## Features

- PostgreSQL 18
- pgvector extension pre-installed and enabled
- Persistent data storage
- PCAI/AIE Framework (Kubernetes-native deployment)
- Configurable resource allocation
- Internal cluster service exposure
- Ready for AI application integration

## Typical Use Cases

### Retrieval-Augmented Generation

Store document embeddings and perform semantic searches to retrieve relevant content for Large Language Models.

### Semantic Search

Search documents, knowledge bases, or product catalogs based on meaning rather than exact keyword matches.

### Recommendation Systems

Identify similar products, documents, users, or other entities using vector similarity.

### Hybrid Queries

Combine standard SQL filtering with vector-based nearest-neighbor search.

```sql
SELECT id, content
FROM documents
WHERE category = 'technical'
ORDER BY embedding <-> '[1.2,0.5,...]'
LIMIT 5;
```

## Architecture

The framework deploys:

- PostgreSQL 18 database server
- pgvector extension
- Persistent Volume Claim (PVC) for data persistence
- PCAI/AIE - Kubernetes Service for internal connectivity

A typical internal PCAI/AIE Kubernetes service address is:

```text
postgresql.<namespace>.svc.cluster.local:5432   # Typical namespace "pgvector"
```

When the service name includes the framework release:

```text
<release>-postgresql.<namespace>.svc.cluster.local:5432
```

## Getting Started

Connect to the database:

```bash
psql -h postgresql -U postgres
```

Enable pgvector if it is not already enabled:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

Create a table containing embeddings:

```sql
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT,
    embedding VECTOR(1024)
);
```

Insert a vector:

```sql
INSERT INTO documents (content, embedding)
VALUES (
    'Example document',
    '[0.1,0.2,0.3]'
);
```

Search for similar vectors:

```sql
SELECT id, content
FROM documents
ORDER BY embedding <-> '[0.1,0.2,0.3]'
LIMIT 10;
```

> The vector dimensions used in inserted values and search queries must match the dimension declared for the vector column.

## Persistence

Database data is stored on a Kubernetes persistent volume so that it can survive pod restarts and framework upgrades.

The target Kubernetes cluster must provide a compatible `StorageClass` and dynamic volume provisioning, unless storage is provisioned manually.

## Requirements

- HPE Private Cloud AI - AI Essentials v. >= 0.10.x (Kubernetes cluster)
- Persistent storage (default configuration in values.yaml: 50GB)
- Available `StorageClass` or manually provisioned persistent volume
- Sufficient CPU, memory (default limits configuration in values.yaml: CPU: 1-4 , Memory: 1-4GB)
- PostgreSQL client tools for command-line administration, if required

## Version Information

| Component | Version |
|---|---:|
| Framework | 0.1.4 |
| PostgreSQL | 18 |
| pgvector | v0.8.7 |

## Notes

- Designed for PCAI/AIE deployments.
- Suitable as the vector database backend for AI applications requiring PostgreSQL compatibility.
- Can be used as a standalone database framework or integrated with applications such as Open WebUI, Langflow, Docling, and custom RAG solutions.
- Supports standard PostgreSQL administration, backup, and monitoring tools.

## License

This framework packages open-source PostgreSQL and pgvector components. Refer to the respective upstream projects for their applicable license terms.

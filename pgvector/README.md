# pgvector Framework for PostgreSQL

## Overview

The **pgvector Framework** provides a PostgreSQL deployment with the **pgvector** extension pre-configured, enabling vector similarity search directly within PostgreSQL.

It is designed for AI and Retrieval-Augmented Generation (RAG) workloads where embeddings and structured application data can be stored and queried from the same database.

## Features


- PostgreSQL
- pgvector extension pre-installed and enabled
- Persistent data storage
- PCAI/AIE Framework (Kubernetes-native deployment)
- Configurable resource allocation
- Internal cluster service exposure
- Ready for AI application integration

**NOTE**
More detailed version information is available in the framework's README.md.

## Typical Use Cases

### Retrieval-Augmented Generation

Store document embeddings and perform semantic searches to retrieve relevant content for Large Language Models.

### Semantic Search

Search documents, knowledge bases, or product catalogs based on meaning rather than exact keyword matches.

## Notes

- Designed for HPE PCAI/AIE deployments.
- Suitable as the vector database backend for AI applications requiring PostgreSQL compatibility.
- Can be used as a standalone database framework or integrated with applications such as Open WebUI, Langflow, Docling, and custom RAG solutions.
- Supports standard PostgreSQL administration, backup, and monitoring tools.

## License

This framework packages open-source PostgreSQL and pgvector components. Refer to the respective upstream projects for their applicable license terms.

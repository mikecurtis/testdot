#!/bin/bash
pnpm dlx ajv-cli validate -s package_list.schema.json -d package_list.json

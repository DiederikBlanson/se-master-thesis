#!/bin/sh



docker run --rm \
    -v "`pwd`:/bag" \
    -ti wholetale/repo2docker_wholetale:v1.2 bdbag --resolve-fetch all /bag

echo "========================================================================"
echo " Open your browser and go to: http://localhost:8787/ "
echo "========================================================================"

# Run the built image
docker run -p 8787:8787 \
  -v "`pwd`/data/data:/WholeTale/data" \
  -v "`pwd`/data/workspace:/WholeTale/workspace" \
  images.wholetale.org/tale/69296a0750c0823234aba7f8383a2ee5:a95b866534e62bc260e044f294957d4e /start.sh

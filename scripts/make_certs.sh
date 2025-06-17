#!/bin/bash

set -e

CERTS_DIR="/home/$USER/certs"
DOMAIN="localhost"
VERBOSE=0

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain=*)
      DOMAIN="${1#*=}"
      shift
      ;;
    --subdomains=*)
      SUBDOMAINS_RAW="${1#*=}"
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    *)
      echo && echo "❌ Unknown option: $1"
      echo "Usage: $0 [--domain=myhome.com] --subdomains=media,cloud,files [--verbose]"
      exit 1
      ;;
  esac
done

# --- Check subdomains ---
if [[ -z "$SUBDOMAINS_RAW" ]]; then
  echo "❌ Missing --subdomains argument"
  echo "Usage: $0 [--domain=myhome.com] --subdomains=media,cloud,files [--verbose]"
  exit 1
fi

# --- Prepare ---
IFS=',' read -r -a SUBDOMAINS <<< "$SUBDOMAINS_RAW"
mkdir -p "$CERTS_DIR"
echo && echo "🔧 Domain base: $DOMAIN"
echo "📂 Output directory: $CERTS_DIR" && echo

# --- Loop through subdomains ---
for SUB in "${SUBDOMAINS[@]}"; do
  FQDN="${SUB}.${DOMAIN}"
  SUBDIR="${CERTS_DIR}/${FQDN}"
  mkdir -p "$SUBDIR"

  echo "🔐 Generating cert for: $FQDN"

  if [[ $VERBOSE -eq 1 ]]; then
    openssl req -x509 -nodes -days 825 \
      -newkey rsa:2048 \
      -keyout "${SUBDIR}/key.pem" \
      -out "${SUBDIR}/cert.pem" \
      -subj "/C=IN/ST=Dev/L=Local/O=Homelab/CN=${FQDN}" \
      -addext "subjectAltName=DNS:${FQDN}"
  else
    openssl req -x509 -nodes -days 825 \
      -newkey rsa:2048 \
      -keyout "${SUBDIR}/key.pem" \
      -out "${SUBDIR}/cert.pem" \
      -subj "/C=IN/ST=Dev/L=Local/O=Homelab/CN=${FQDN}" \
      -addext "subjectAltName=DNS:${FQDN}" > /dev/null 2>&1
  fi

  echo "✅ Created: ${SUBDIR}/cert.pem and key.pem" && echo
done

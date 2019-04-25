#!/bin/bash

# gitlab-runner data directory
DATA_DIR="/etc/gitlab-runner"
CONFIG_FILE=${CONFIG_FILE:-$DATA_DIR/config.toml}
TMPL_CONFIG_FILE=${TMPL_CONFIG_FILE:-$DATA_DIR/runner.toml}
# custom certificate authority path
CA_CERTIFICATES_PATH=${CA_CERTIFICATES_PATH:-$DATA_DIR/certs/ca.crt}
LOCAL_CA_PATH="/usr/local/share/ca-certificates/ca.crt"
if [[ "X${GITLAB_RUNNER_NAME}" == "X" ]];then
    GITLAB_RUNNER_NAME=$(hostname)
fi
if [[ "X${GITLAB_TOKEN}" != "X" ]];then
    gitlab-runner register --non-interactive --executor=docker \
        --url https://gitlab --registration-token ${GITLAB_TOKEN} \
        --docker-image=alpine:3.8 --docker-host=unix:///var/run/docker.sock \
        --docker-network-mode=host --docker-volumes=/var/run/docker.sock:/var/run/docker.sock \
        --docker-volumes=/cache
fi

update_ca() {
  echo "Updating CA certificates..."
  cp "${CA_CERTIFICATES_PATH}" "${LOCAL_CA_PATH}"
  update-ca-certificates --fresh >/dev/null
}

if [ -f "${CA_CERTIFICATES_PATH}" ]; then
  # update the ca if the custom ca is different than the current
  cmp --silent "${CA_CERTIFICATES_PATH}" "${LOCAL_CA_PATH}" || update_ca
fi

# launch gitlab-runner passing all arguments
exec gitlab-runner "$@"

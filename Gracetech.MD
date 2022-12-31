# GraceTech Development

## Installation

- cp env.example .env
- (edit .env, update `PUBLIC_URL`)
- ./gen-passwords.sh
- mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
- make build_jicofo && make build_jvb && make build_web && make build_prosody && docker-compose up

## Rebuild after image (web, prosody) change

- make build_jicofo && make build_jvb && make build_web && make build_prosody && docker-compose up -d --force-recreate prosody web

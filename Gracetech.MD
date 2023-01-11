# GraceTech Development

## Installation

- cp env.example .env
- (edit .env, update `PUBLIC_URL`)
- ./gen-passwords.sh
- mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
- docker-compose down && docker image prune -a -f && docker system prune -a -f && make build_jicofo && make build_jvb && make build_web && make build_prosody && docker-compose up -d

## Debug web changes

- make build_web && docker-compose up -d --force-recreate web && docker-compose logs -f web


## Debug prosody changes
- make build_prosody && docker-compose up -d --force-recreate prosody && docker-compose logs -f prosody

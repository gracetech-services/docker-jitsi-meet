# GraceTech Development

## Installation

- cp env.example .env
- (edit .env, update `PUBLIC_URL`)
- ./gen-passwords.sh
- mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
- make build_web
- make build_prosody
- docker-compose up -d

## Rebuild after image change

- make build_web
- make build_prosody
- docker-compose down
- docker-compose up -d

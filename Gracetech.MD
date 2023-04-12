# GraceTech Development

## First Time Installation

- cp env.example .env
- (edit .env, update `PUBLIC_URL`)
- ./gen-passwords.sh
- mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
- docker-compose down && docker image prune -a -f && docker system prune -a -f && make all && docker-compose up -d

## Rebuild web changes

- FORCE_REBUILD=1 make build_web && docker-compose up -d --force-recreate web && docker-compose logs -f web

## Rebuild prosody changes

- FORCE_REBUILD=1 make build_prosody && docker-compose up -d --force-recreate prosody && docker-compose logs -f prosody

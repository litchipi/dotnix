# Sparta

Upgrade to 23.11 with working gnome extensions, and zenith

# Suzie

<!-- TODO: Find a way to connect to services when working remotely -->

Backup old suzie setup:
- Every git repository cloned locally (after filter)
- Nextcloud data
- Paperless data
- Shiori data

Do not use nginx subdomains, simply expose other ports
In /etc/hosts of personnal laptop, add `suzie.local` for the IP address
Then use port number inside bookmark (`suzie.local:8081`)

Static IP address

Services:
[ ] Forgejo
[ ] Forgejo runners
[ ] Paperless
[ ] Shiori
[ ] FTP server
[ ] Vikunja

Suzie systemd services:
[ ] Auto backup of remote website (blog):
  - Setup scripts
  - Logs

[ ] Restic backup
  - Forgejo dump (in forgejo config)
  - Paperless documents
  - Shiori bookmarks
  - Remote websites backups

[ ] Auto system updates, reboot at night (3 am ?)

Admin scripts on laptop:
[ ] Check if last update succeeded
[ ] Reboot remote server
[ ] Start / Stop vulnerable VM

Services on laptop:
[ ] Fetch backup of suzie, store it locally
[ ] Store backup of laptop files on suzie

## Additionnal services to look at

- Monica (Relations manager)
- Penpot (Design / Prototyping platform)
- Photoprism (Photo hosting app)

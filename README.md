# linux-bash-script-generate-WHM-server-domains-as-php-file

Linux bash script for a WHM/cPanel server admin to discover all hosted domains/subdomains/addon domains and create .php file out of that, clickable links so admin can open hosted webpages to check what is hosted.

Everytime the script is run (as a cronjob example), it generate the .php file in certain web path so admin can browse site list.

Features:
- exclude suspended accounts
- exclude domains pointed to other servers than localhost
- exclude user defined cpanel accounts and their websites

Installation:
Edit the variables weblist and webacctusr

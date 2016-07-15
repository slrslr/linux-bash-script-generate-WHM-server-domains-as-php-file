#set -ex
# Linux bash script for the cPanel/WHM server. It will browse all domains, subdomains, addon domains hosted on local cPanel server.
# It will create webpage on local webpath which will include clickable list of all mentioned hosted sites and exclude sites:
# - in default state (empty Index Of page)
# - suspended
# - domain pointed to different server
# - owner cpanel account is in exclude list
# It will also show usernames and user emails and a few files in cpanel accounts next to each listed domain/subdomain
# This way server admin can conveniently browse active hosted sites and see what is hosted

# local full web path to .php or .htm/l file where to store clickable list of hosted sites
weblist=/home/USERNAMEHERE/public_html/domeny/DOMAINHERE.com/RANDOMNAMEHERE.php
webacctusr=USERNAMMEHERE
# exclude sites of certain users, NO spaces
excludedcpanels="cpanel1,cpanel2,cpanel3"

# If new hosting accounts on your server contains any files like robots.txt, you should enter it here. We exclude sites that do not contain any other files/are in default state
filesonindexof="cgi-bin|favicon.ico|robots.txt"

# excluded files when listing www directory contents of a cpanel
excludedfiles=".jpg|.png|.gif|.txt|.xml|.csv|.shtml|error_log|cgi_bin|htaccess|favicon|wp-|.ini|.db"

# directory where this bash script is located
thisscriptdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# this server IP
localip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

# discover suspended cpanels
suspended_cpanels=$(ls -A1 /var/cpanel/suspended)

# domains and its users
domains_and_users=$(cat /etc/domainusers)

# ---------------- no need to further edit below this line -------------------------------

# erase files to prevent duplicity from previous run
> $weblist

echo "Site list last updated <strong>$(date)</strong> by $thisscriptdir and sitelist does not contain admin excluded, suspended, not resolving to $(hostname) sites. Last serv. bckp: $(ls -lht /backup/|head -n3|tail -n1)<br>" >> $weblist

sitesnumber="$(cat /etc/localdomains|wc -l)" && echo "There is $sitesnumber sites"

i=0
for site in $(cat /etc/localdomains);do
i=$[$i+1]

siteuser=$(/scripts/whoowns $site)

# exclude sites of certain users
if [[ "$(echo $excludedcpanels)" == *"$siteuser"* ]];then
echo "Excluding site as its owner is on blacklist/excluded: $site ($i/$sitesnumber)"
# skip to next site
continue
fi

if [[ "$(host $site)" != *"$localip"* ]];then
echo "$site is not pointed to this server, skip it. ($i/$sitesnumber)"
continue
fi

# "good, site points to this server, but lets check if its not suspended. If it is, then continue with next site."
if [[ "$(echo "$suspended_cpanels")" == *"$siteuser"* ]];then
# "site is suspended so i dont care about it, do not add it into the list, skip to next one"
continue
fi

sitecontent="$(curl --silent --show-error --max-time 5 $site)"
sleep 3

# If website contains no index, Index of page is shown. If this page is empty or contains only defaut files, we skip such site
if [[ "$sitecontent" == *"Index of"* && "$(echo "$sitecontent"|grep -vE "$filesonindexof"|wc -l)" == "9" ]];then
echo "Site is in default state/has no index, no files, im not interested in this site to be listed, skip. $site ($i/$sitesnumber)"
# skip to next site
continue
fi
echo "Site is in modiffied state, will be reported: $site ($i/$sitesnumber)"

# "Adding site to the active list"
echo "<strong><a href=\"http://$site\" target=\"_blank\">http://$site</a></strong> - A few cPanel <strong>$siteuser</strong> / $(cat /var/cpanel/users/$siteuser|grep CONTACTEMAIL=|cut -c 14-) items: $(ls -m --group-directories-first /home/$siteuser/public_html/|grep -vE \"$excludedfiles\"|head -1)<br />" >> $weblist
#fi
done
chown $webacctusr:$webacctusr $weblist
#

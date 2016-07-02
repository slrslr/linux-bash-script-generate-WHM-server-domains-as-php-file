#set -ex
# Bash script to extract list of websites (including subdomains & addon domains) hosted on an WHM/cPanel server
# & create clickable list accessible from an local web path

# web path to .php or .htm/l file where to store clickable list of hosted sites
weblist=/home/CPANELUSERNAMEXY/public_html/SOME_NAME.php
webacctusr=CPANELUSERNAMEXY
# exclude sites of certain users:
userexclude1=usernamehere1
userexclude2=usernamehere2
userexclude3=usernamehere3
userexclude4=usernamehere4

# directory where this bash script is located
thisscriptdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# this server IP
localip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

# discover suspended cpanels
suspended_cpanels=$(ls -A1 /var/cpanel/suspended)

# domains and its users
domains_and_users=$(cat /etc/domainusers)

# no need to further edit below this line -------------------------------

# erase files to prevent duplicity from previous run
>$thisscriptdir/sitesfromdomlogs && >$thisscriptdir/httpsitesfromdomlogs && >$thisscriptdir/htmlsitesfromdomlogs && >$thisscriptdir/sitesfromdomlogsactive

for site in $(cat /etc/localdomains);do

siteuser=$(/scripts/whoowns $site)

# exclude sites of certain users
if [[ "$siteuser" == "$userexclude1" || "$siteuser" == "$userexclude2" || "$siteuser" == "$userexclude3" || "$siteuser" == "$userexclude4" ]];then
# skip to next site
continue
fi

#if [[ "$(host $site)" == *"$localip"* ]];then
# "good, site points to this server, but lets check if its not suspended. If it is, then continue with next site."
if [[ "$(echo "$suspended_cpanels")" == *"$siteuser"* ]];then
# "site is suspended so i dont care about it, do not add it into the list, skip to next one"
continue
fi

if [[ "$(host $site)" == *"not found: 3(NXDOMAIN)"* ]];then
# do not report this site as domain not resolve to hosting, continue next site
continue
fi

# This condition is for my hosting only. New hosting account has "Index of /" page with 3 files on it. So if client changed nothing, i want to skip/exclude his site
#if [[ "$(curl --silent --max-time 3 $site)" == *"Index of"* && "$(curl --silent --max-time 3 $site|grep -vE "cgi-bin|favicon.ico|robots.txt"|wc -l)" == "9" ]];then
#continue
#fi

# "Adding site to the active list"
echo $site >> $thisscriptdir/sitesfromdomlogsactive
#fi
done

# add httpd:// prefix to the sites
sed -e 's/^/http:\/\//' $thisscriptdir/sitesfromdomlogsactive > $thisscriptdir/httpsitesfromdomlogs

# create html links list out of url list
for url in $(cat $thisscriptdir/httpsitesfromdomlogs);do
echo "<a href=\"$url\" target=\"_blank\">$url</a><br />" >> $thisscriptdir/htmlsitesfromdomlogs
done

# copy file with html links to local web path so its accessible from there & assign proper user permissions to the file
cp $thisscriptdir/htmlsitesfromdomlogs $weblist
chown $webacctusr:$webacctusr $weblist

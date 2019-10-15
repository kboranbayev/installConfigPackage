#!/bin/bash


# httpd conf file paths
orgF="/etc/httpd/conf.d/userdir.conf-2"
newF="/etc/httpd/conf.d/userdir.conf"


# Adding a new user and password
if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p $pass $username
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system"
	exit 2
fi

echo "Configuring Apache"
# creating a new Directory
mkdir /home/$username/public_html

# Copying old conf files just in case
cp /etc/httpd/conf.d/userdir.conf /etc/httpd/conf.d/userdir.conf-old-2
cp /etc/httpd/conf.d/userdir.conf /etc/httpd/conf.d/userdir.conf-old


sudo sed -i -e 's/UserDir disabled/#UserDir disabled/' $newF
sudo sed -i -e 's/#UserDir public_html/UserDir public_html/' $newF

# Comment old <Directory />
sudo sed -i -e 's/<Directory/#<Directory/' $newF
sudo sed -i -e 's/AllowOverride FileInfo/#AllowOverride FileInfo/' $newF
sudo sed -i -e 's/Options MultiViews/#Options MultiViews/' $newF
sudo sed -i -e 's/Require method GET POST OPTIONS/#Require method GET POST OPTIONS/' $newF
sudo sed -i -e 's/<\/Directory/#<\/Directory/' $newF

# Adding new <Directory />
sudo echo "
<Directory /home/$username>
    AllowOverride None
    AuthUserFile /var/www/html/passwords/foobar
    AuthGroupFile /dev/null
    AuthName $username
    AuthType Basic
    <Limit GET>
        require valid-user
        order deny,allow
        deny from all
        allow from all
    </Limit>
</Directory>" >> /etc/httpd/conf.d/userdir.conf

# changing permissions
sudo chmod -R 711 /home/$username
sudo chmod -R 755 /home/$username/public_html

# creating dummy index.html for display
sudo echo "<h1>Hello, its $username</h1>" >> /home/$username/public_html/index.html

# create directory for generated htpasswd file 
sudo mkdir /var/www/html/passwords
sudo chmod -R 711 /var/www/html/passwords

# generate htpasswd for $username and store it in foobar
sudo htpasswd -b -c /var/www/html/passwords/foobar $username $password
    [ $? -eq 0 ] && echo "User has been added to foobar!" || echo "Failed to add a user to foobar!"

# restart httpd.service
sudo systemctl restart httpd.service

echo "Configuring NFS"

# test file for nfs
echo "Creating test.txt. Write something:"
sudo cat > /home/$username/test.txt

# change access persmission for that file
sudo chmod 777 /home/$username/test.txt



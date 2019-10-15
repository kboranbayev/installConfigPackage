#!/bin/bash


# httpd conf file paths
orgF="/etc/httpd/conf.d/userdir.conf-old"
newF="/etc/httpd/conf.d/userdir.conf"

# nfs
orgN="/etc/exports-old"
newN="/etc/exports"

# samba
orgS="/etc/samba/smb.conf-old"
newS="/etc/samba/smb.conf" 

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
# httpd files
if [ -f $orgF ]
then
    sudo cp $orgF $newF
else
    sudo cp $newF $orgF
fi
if [ -f $orgN ]
then
    sudo cp $orgN $newN
else
    sudo cp $newN $orgN
fi
if [ -f $orgS ]
then
    sudo cp $orgS $newS
else
    sudo cp $newS $orgS
fi

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
#echo "Creating test.txt. Write something:"
#sudo cat > /home/$username/test.txt

sudo echo "hello" > /home/$username/test.txt

# change access persmission for that file
sudo chmod 777 /home/$username/test.txt

sudo echo "/home/$username 192.168.0.0/24(rw,no_root_squash)" >> $newN

sudo systemctl restart nfs-server.service

echo "Configuring Samba"

# adding new label for windows network drive mapping
sudo echo "
[NFSHARE]
    path = /home/$username
    public = yes
    writable = yes
    printable = no
" >> $newS

# generate smbpasswd for a $username
#sudo smbpasswd -a $username
echo "smbpasswd"
(echo $password; echo $password) | smbpasswd -a $username -s
    [ $? -eq 0 ] && echo "User has been added to smb!" || echo "Failed to add a user to smb!"

sudo systemctl restart smb.service

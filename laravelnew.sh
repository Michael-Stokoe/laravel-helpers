#!/usr/bin/bash

# Installation:
# Either copy & paste the full function into your .bashrc (or similar)
# OR save this file as laravelnew.sh and add source ~/laravelnew.sh (or wherever it was saved to) to your .bashrc (or similar)

# New Project Setup.
# 
# Copies .env, replaces APP_NAME, APP_URL, DB_HOST, DB_DATABASE and REDIS_HOST
# You may need to change the variables below to account for your own setup.
#
# It is important that you keep your projects under ~/code or ~/projects.
# This script will detect which you're using. (If you have both, it will place the new project into ~/projects)

# IP address you access homestead through. This is defined in homestead.yaml
homesteadip=192.168.10.10

# Top-level Domain: ex. http://app.test
tld=test

# Homestead directory
hsdir=~/Homestead

# Homestead.yaml location
hsyaml=~/Homestead/Homestead.yaml

# Database user
dbuser=homestead
# Database password
dbpassword=secret

# Package manager (JS) "yarn" or "npm"
packagemanager=npm

echo "Finding projects directory..."

if [ -d "/home/$USER/code" ]
then
    echo "Found projects under 'code' directory"
    cd /home/$USER/code
fi

if [ -d "/home/$USER/projects" ]
then
    echo "Found projects under 'projects' directory"
    cd /home/$USER/projects
fi

projectname=$1

echo "Creating new Laravel project called $projectname"
laravel new $projectname 1>/dev/null

cd ./$projectname

# Change your editor here if you don't use VS Code.
code -g ./
xdg-open ./ 1>/dev/null

sed -i "s/APP_NAME=Laravel/APP_NAME='$projectname'/g" .env
sed -i "s/APP_URL=http:\/\/localhost/APP_URL=http:\/\/$projectname.$tld/g" .env
sed -i "s/DB_HOST=127\.0\.0\.1/DB_HOST=$homesteadip/g" .env
sed -i "s/DB_DATABASE=homestead/DB_DATABASE='$projectname'/g" .env
sed -i "s/DB_USERNAME=root/DB_USERNAME='$dbuser'/g" .env
sed -i "s/DB_PASSWORD=/DB_PASSWORD='$dbpassword'/g" .env
sed -i "s/REDIS_HOST=127\.0\.0\.1/REDIS_HOST=$homesteadip/g" .env

# Comment out the following if you don't use /etc/hosts
if grep -Fxq "$homesteadip $projectname.$tld" /etc/hosts
then
    echo "Hosts entry already exists!"
else
    echo "Hosts entry didn't exist for application."
    echo "Adding hosts entry for this application."
    echo "$homesteadip $projectname.$tld" | sudo tee -a /etc/hosts
    echo "Hosts entry added. Your app will be live at http://$projectname.$tld"
fi

# Comment out the following if you want to write the homestead.yaml entries yourself.
if grep -Fq "$projectname.$tld" $hsyaml
then
    echo "Homestead.yaml entry already exists!"
else
    echo "No entries in $hsyaml for this application, adding them now."
    sed -i "/^sites:/a \ \ \ \ - map: $projectname.$tld" $hsyaml
    sed -i "/^\ \ \ \ - map: $projectname.$tld/a \ \ \ \ \ \ to: /home/vagrant/projects/$projectname/public" $hsyaml
    echo "Adding database with name $projectname to $hsyaml"
    sed -i "/^databases:/a \ \ \ \ - $projectname" $hsyaml
fi

echo "Running $packagemanager & composer"

if [ "$packagemanager" = "yarn" ]
then
    yarn 1>/dev/null
elif [ "$packagemanager" = "npm" ]
then
    npm install 1>/dev/null
else
    echo "$packagemanager isn't a known package manager. Moving on."
fi

if ! [ -f artisan ]
then
    echo "Artisan not detected. Exiting."
    return 0
fi

echo "Generating App Key"
php artisan key:generate

echo "Installing extra dependencies..."
composer require --dev itsgoingd/clockwork 1>/dev/null
composer require --dev barryvdh/laravel-ide-helper 1>/dev/null
php artisan ide-helper:generate
# composer require spatie/laravel-permission 1>/dev/null
echo "Publishing assets..."
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag="migrations"
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag="config"


# Comment out these 3 lines if you DO NOT wish to reprovision your vagrant box after doing this setup.
echo "Reprovisioning Vagrant Box"
cd $hsdir
vagrant up --provision 1>/dev/null
echo "Finished provision."
cd -

# Perhaps not entirely useful on a new project, but at least it makes sure you've set up the scripts correctly.
echo "Running database migrations"
php artisan migrate:fresh --force --seed  1>/dev/null
echo "Migrated."

echo "ALL DONE!"
echo "Find your app online at:"
echo "https://$projectname.$tld"
echo "or"
echo "http://$projectname.$tld"

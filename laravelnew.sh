#!/usr/bin/bash

# Installation:
# Either copy & paste the full function into your .bashrc (or similar)
# OR save this file as laravelnew.sh and add source ~/laravelnew.sh (or wherever it was saved to) to your .bashrc (or similar)

function laravelnew () {
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

    # Database password
    dbpassword=secret
    
    echo "Finding projects directory..."
    
    if [ -d "~/code" ]; then
        echo "Found projects under 'code' directory"
        cd ~/code
    fi

    if [ -d "~/projects" ]; then
        echo "Found projects under 'projects' directory"
        cd ~/projects
    fi

    if ! [ command -v laravel ]; then
        echo "'laravel' command doesn't seem to be in your PATH"
        echo "Add export PATH=$PATH:~/.config/composer/vendor/bin to your ~/.bashrc or similar"
        echo "...and make sure you've ran composer global install laravel/installer"
        cd -
        return 0
    fi

    if ! [ command -v composer ]; then
        echo "Please install composer first."
        return 0
    fi

    echo "Finding (js) package manager..."
    packagemanager=yarn
    if ! [ command -v yarn ]; then
        echo "Yarn is not installed, checking for npm..."
        if ! [ command -v npm ]; then
            echo "npm isn't installed either. Exiting."
            return 0
        fi
        packagemanager=npm
    fi

    projectname=$1

    echo "Creating new Laravel project called $projectname"
    laravel new $projectname

    cd ./$projectname

    # Current directory name. (To use as APP_NAME, APP_URL and MySQL DB name).

    if ! [ -f .env ]; then
        if ! [ -f .env.example ]; then
            echo "Please make sure .env.example exists."
            return 0
        fi
        
        echo "Cloning .env.example into .env."
        cp .env.example .env
    fi

    sed -i "s/APP_NAME=Laravel/APP_NAME='$projectname'/g" .env
    sed -i "s/APP_URL=http:\/\/localhost/APP_URL=http:\/\/$projectname.$tld/g" .env
    sed -i "s/DB_HOST=127\.0\.0\.1/DB_HOST=$homesteadip/g" .env
    sed -i "s/DB_DATABASE=homestead/DB_DATABASE='$projectname'/g" .env
    sed -i "s/DB_PASSWORD=/DB_PASSWORD='$dbpassword'/g" .env
    sed -i "s/REDIS_HOST=127\.0\.0\.1/REDIS_HOST=$homesteadip/g" .env

    # Comment out the following if you don't use /etc/hosts
    if grep -q "$homesteadip $projectname.$tld" /etc/hosts; then
        echo "Hosts entry didn't exist for application."
        echo "Adding hosts entry for this application."
        echo "\n$homesteadip $projectname.$tld" | sudo tee -a /etc/hosts
        echo "Hosts entry added. Your app will be live at http://$projectname.$tld"
    fi

    # Comment out the following if you want to write the homestead.yaml entries yourself.
    if grep -q "$projectname.$tld" $hsyaml; then
        echo "No entries in $hsyaml for this application, adding them now."
        sed -i "/^sites:/a \ \ \ \ - map: $projectname.$tld" $hsyaml
        sed -i "/^\ \ \ \ - map: $projectname.$tld/a \ \ \ \ \ \ to: /home/vagrant/projects/$projectname/public \n" $hsyaml
        echo "Adding database with name $projectname to $hsyaml"
        sed -i "/^databases:/a \ \ \ \ - $projectname" $hsyaml
    fi
    
    echo "Running $packagemanager & composer"

    if [ "$packagemanager" = "yarn" ]; then
        yarn
    elif [ "$packagemanager" = "npm" ]; then
        npm install
    else
        echo "$packagemanager isn't a known package manager. Moving on."
    fi

    composer install

    if ! [ -f artisan ]; then
        echo "Artisan not detected. Exiting."
        return 0
    fi

    echo "Generating App Key"
    php artisan key:generate
    
    echo "Installing extra dependencies..."
    echo "Installing itsgoingd/clockwork"
    composer require --dev itsgoingd/clockwork
    echo "Installing barryvdh/laravel-ide-helper"
    composer require --dev barryvdh/laravel-ide-helper
    echo "Generating ide helper files..."
    php artisan ide-helper:generate
    echo "Installing protoqol/prequel"
    composer require --dev protoqol/prequel
    php artisan prequel:install
    echo "Installing spatie/laravel-permission"
    composer require spatie/laravel-permission
    echo "Publishing assets..."
    php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag="migrations"
    php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag="config"


    # Comment out these 3 lines if you DO NOT wish to reprovision your vagrant box after doing this setup.
    echo "Reprovisioning Vagrant Box"
    cd $hsdir
    vagrant up --provision
    cd -
    
    # Perhaps not entirely useful on a new project, but at least it makes sure you've set up the scripts correctly.
    echo "Running database migrations"
    php artisan migrate:fresh --force --seed

    if [ command -v pstorm ]; then
        pstorm ./
    fi

    if [ command -v code ]; then
        code -g ./
    fi

    xdg-open ./

    echo "ALL DONE!"
    echo "Find your app online at:"
    echo "https://$projectname.$tld"
    echo "or"
    echo "http://$projectname.$tld"
}

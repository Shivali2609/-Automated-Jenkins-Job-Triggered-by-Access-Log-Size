crontab -e
0 2 * * * /home/ubuntu/backup_script.sh >> /home/ubuntu/cron.log 2>&1
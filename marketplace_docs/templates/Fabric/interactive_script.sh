#!/usr/bin/env bash
clear

cat <<EOM

Welcome to Zulip setup! You will need:
- An email address for support and error emails, like ops@example.com. You can change
  this email address later.
- A hostname for the Zulip server, like chat.example.com. The hostname must be a valid
  domain with DNS configured to point to the IP address of this droplet.

Press Ctrl+C to exit setup for now. You will be prompted again on your next login.

Press Enter to continue.

EOM

read -r _

while  [ -z "${email}" ] || [ -z "${hostname}" ]; do
    read -r -p "Email address for support and error emails (e.g. ops@example.com): " email
    read -r -p "Hostname (e.g. chat.example.com): " hostname
    echo ""
done

SERVICES_FLAGS=""
echo ""
echo "Would you like to automatically register your server for push notifications?"
echo "For details on why a centralized push notification service is necessary, see:"
echo "    <https://zulip.com/doc-permalinks/why-service>"
read -r -p "Answer [Y/n]: " push_prompt
case "${push_prompt,,}" in
    "" | y | yes)
        SERVICES_FLAGS="--push-notifications"

        echo ""
        echo "Should your server upload aggregate usage statistics to the push notification service?"
        echo "For details, see:"
        echo "    <https://zulip.com/doc-permalinks/usage-statistics>"
        read -r -p "Answer [Y/n]: " stats_prompt
        case "${stats_prompt,,}" in
            n | no)
                echo "Aggregate usage statistics will not be uploaded."
                SERVICES_FLAGS="${SERVICES_FLAGS} --no-submit-usage-statistics"
                ;;
            *)
                echo "Agrregate usage statistics will be uploaded."
                ;;
        esac
        ;;
    *)
        echo "Push notifications will not be enabled; continuing with installation..."
        ENABLE_PUSH_NOTIFICATIONS=0
        ;;
esac
sleep 1.5

cat <<EOM

Configuring Zulip. This might take a few minutes.


EOM

sudo service nginx stop

array=(./zulip-server-*)
"${array[0]}"/scripts/setup/install ${SERVICES_FLAGS} --certbot --email="$email" --hostname="$hostname" --no-dist-upgrade
if [ "$?" = 1 ]; then
    echo "For troubleshooting, see https://zulip.readthedocs.io/en/stable/production/troubleshooting.html."
    echo -e "\n"
    echo -e "\e[33mRun the following command or log in to this server again to retry installation\e[0m"
    echo "  /opt/zulip/interactive_script.sh"
else
    cp -f /etc/skel/.zulip_bashrc /root/.bashrc
    touch /opt/zulip/.configured
    # Re-enable the systemd job we disabled in image creation.
    systemctl enable --quiet apt-daily.timer apt-daily-upgrade.timer
fi

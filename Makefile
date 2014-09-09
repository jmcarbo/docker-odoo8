build:
	docker build -t jmcarbo/odoo8 .

run:
	docker run -t -i --rm -p 443:443 -p 8069:8069 -p 5432:5432  -e DB_USER='deploy' -e DB_PASSWORD='a123456' -e DB_HOST='localhost' -e DB_PORT=5432 -e ADDONS_PATH='/addons' --name=odoo jmcarbo/odoo8 /sbin/my_init -- bash -l


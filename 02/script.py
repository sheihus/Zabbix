# registering host in zabbix with linux template

import os, requests, json, sys, socket, subprocess
from requests.auth import HTTPBasicAuth

hostip='192.168.56.101'

# server

zabbix_server = '192.168.56.100'
zabbix_api_admin_name = "Admin"
zabbix_api_admin_password = "zabbix"
group = "CloudHosts"

hostname = socket.gethostname()

#post
def post(request):
    headers = {'content-type': 'application/json-rpc'}
    print(json.dumps(request))
    return requests.post(
        "http://"+zabbix_server+":/zabbix/api_jsonrpc.php",
         data=json.dumps(request),
         headers=headers,
         auth=HTTPBasicAuth(zabbix_api_admin_name, zabbix_api_admin_password)
    )



# token

auth_token = post({
    "jsonrpc": "2.0",
    "method": "user.login",
    "id": 1,
    "auth": None,
    "params": {
         "user": zabbix_api_admin_name,
         "password": zabbix_api_admin_password
     }

    }
).json()["result"]


def group_create(namegroup, auth_token):
    return post({
    "jsonrpc": "2.0",
    "method": "hostgroup.create",
    "params": {
        "name": namegroup
    },
    "auth": auth_token,
    "id": 1
        }).json()["result"]["groupids"]


group_id = group_create(namegroup, auth_token)


# select template for linux
template_id = post({
    "jsonrpc": "2.0",
    "method": "template.get",
    "params": {
        "output": "extend",
        "filter": {
            "host": [
                "Template OS Linux"
            ]
        }
    },
    "auth": auth_token,
    "id": 1
}).json()['result'][0]['templateid']


# registering host
def register_host(hostname, hostip, group_id, template_id, auth_token):
    post({
    "jsonrpc": "2.0",
    "method": "host.create",
    "params": {
        "host": hostname,
        "interfaces": [
            {
                "type": 1,
                "main": 1,
                "useip": 1,
                "ip": hostip,
                "dns": "",
                "port": "10050"
            }
        ],
        "groups": [
            {
                "groupid": group_id[0]
            }
        ],
        "templates": [
            {
                "templateid": template_id
            }
        ],
        "inventory_mode": 0,
        "inventory": {
            "macaddress_a": "11111",
            "macaddress_b": "22222"
        }
    },
    "auth": auth_token,
    "id": 1
    })


#register host with template
register_host(hostname, hostip, group_id, template_id, auth_token)

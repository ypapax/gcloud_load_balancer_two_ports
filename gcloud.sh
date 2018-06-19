#!/usr/bin/env bash
set -ex

createAll(){
	template_create
	create_managed_group
	set_named_ports
	set +e; create_health_check80; set -e;
	set +e; create_health_check8080; set -e;
	create_backend
	create_backend2
	add_backend
	add_backend2
	url_map
	url_map2
	create_http_proxy1
	create_http_proxy2
	forwarding_rule
	curlall
}

curlall(){
	curlWorkers
	curlBalancers
}

deleteAll(){
	set +e;
	forwarding_rule_delete
	delete_http_proxy1
	delete_http_proxy2
	url_map_delete1
	url_map_delete2
	delete_backend
	delete_backend2
	delete_group
	template_delete
	set -e;
}

template_create(){
	gcloud beta compute instance-templates create-with-container mytemplate \
     --container-image ypapax/two_ports
}

template_delete(){
	gcloud beta compute instance-templates delete mytemplate --quiet
}


create_managed_group(){
	gcloud compute instance-groups managed create twoports-group \
    --base-instance-name twoports \
    --size 2 \
    --template mytemplate \
    --zone europe-west1-b
}

delete_group(){
	gcloud compute instance-groups managed delete twoports-group --quiet
}

set_named_ports(){
	gcloud compute instance-groups managed set-named-ports twoports-group \
   --named-ports app80:80,app8080:8080 \
	--zone europe-west1-b
}

create_health_check80(){
	gcloud compute health-checks create http healthcheck80 --port 80 \
	    --check-interval 30s \
	    --healthy-threshold 1 \
	    --timeout 10s \
	    --unhealthy-threshold 3
}

create_health_check8080(){
	gcloud compute health-checks create http healthcheck8080 --port 8080 \
	    --check-interval 30s \
	    --healthy-threshold 1 \
	    --timeout 10s \
	    --unhealthy-threshold 3
}

create_backend(){
	gcloud compute backend-services create twoports-backend --global \
		--health-checks=healthcheck80 \
		--port-name app80
}

create_backend2(){
	gcloud compute backend-services create twoports-backend2 --global \
		--health-checks=healthcheck8080 \
		--port-name app8080
}

delete_backend(){
	gcloud compute backend-services delete twoports-backend --global --quiet
}

delete_backend2(){
	gcloud compute backend-services delete twoports-backend2 --global --quiet
}



add_backend(){
	gcloud compute backend-services add-backend twoports-backend \
	--global \
	--instance-group=twoports-group \
	--instance-group-zone europe-west1-b
}

add_backend2(){
	gcloud compute backend-services add-backend twoports-backend2 \
	--global \
	--instance-group=twoports-group \
	--instance-group-zone europe-west1-b
}

url_map(){
	gcloud compute url-maps create twoports-map1 --default-service twoports-backend
}

url_map2(){
	gcloud compute url-maps create twoports-map2 --default-service twoports-backend2
}

url_map_delete1(){
	gcloud compute url-maps delete twoports-map1 --quiet
}

url_map_delete2(){
	gcloud compute url-maps delete twoports-map2 --quiet
}

create_http_proxy1(){
	gcloud compute target-http-proxies create twoports-proxy1 --url-map twoports-map1
}

create_http_proxy2(){
	gcloud compute target-http-proxies create twoports-proxy2 --url-map twoports-map2
}

delete_http_proxy1(){
	gcloud compute target-http-proxies delete twoports-proxy1 --quiet
}

delete_http_proxy2(){
	gcloud compute target-http-proxies delete twoports-proxy2 --quiet
}

forwarding_rule(){
	gcloud compute forwarding-rules create forwarding-rule80 --global --target-http-proxy twoports-proxy1 --ports 80
	gcloud compute forwarding-rules create forwarding-rule8080 --global --target-http-proxy twoports-proxy2 --ports 8080
}

describe_forwarding_rule(){
	gcloud compute forwarding-rules describe forwarding-rule80 --global
	gcloud compute forwarding-rules describe forwarding-rule8080 --global
}

forwarding_rule_delete(){
	gcloud compute forwarding-rules delete forwarding-rule80 --global --quiet
	gcloud compute forwarding-rules delete forwarding-rule8080 --global --quiet
}

load_balancer_frontend_ip(){
	rule=$1
	gcloud compute forwarding-rules describe $rule --global | grep IPAddress | awk '{print $2}'
}

workers_ips(){
	gcloud compute instances list | grep twoports- | awk '{print $5}'
}

curl80(){
	ip1=$(load_balancer_frontend_ip forwarding-rule80)
	curl $ip1:80
}

curl8080(){
	ip2=$(load_balancer_frontend_ip forwarding-rule8080)
	curl $ip2:8080
}

curlBalancers(){
	delim
	delim
	curl80
	delim
	curl8080
}

curlWorkers(){
	delim
	delim
	curlWorkers80
	delim
	curlWorkers8080
}

curlWorkers80(){
	for ip in $(workers_ips); do
		curl $ip:80 | grep 80
	done
}

curlWorkers8080(){
	for ip in $(workers_ips); do
		curl $ip:8080 | grep 8080
	done
}

delim(){
	set +x
	echo "------------------"
	set -x
}
delim2(){
	set +x
	echo "------------------"
	echo "------------------"
	set -x
}

describeAll(){
	delim
	get_name_ports
	delim2
	describeBackends
}

get_name_ports(){
	gcloud compute instance-groups managed get-named-ports twoports-group
}

describeBackends(){
	delim
	gcloud compute backend-services describe twoports-backend --global | tee >(cat 1>&2) | grep 80
	delim
	gcloud compute backend-services describe twoports-backend2 --global | tee >(cat 1>&2) | grep 8080
}

$@
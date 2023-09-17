#!/bin/bash

#############################################
#                                           #
#        kubernetes version upgrade         #
#                                           # 
############################################# 

#升级master节点
#替换成指定版本(1.24及以上版本需自行升级CNI插件)。注：!!!不能跨版本!!!,使用此命令查询目标版本：yum list --showduplicates kubeadm --disableexcludes=kubernetes 

#腾空节点
for i in {1..3};do
  sudo kubectl drain k8s-master$i --ignore-daemonsets --force;
done

#升级 kubelet、kubectl、kubeadm
for i in {1..3};do  #根据master节点数量自调整
  ssh k8s-master$i sudo yum install kubeadm-1.23.17 kubelet-1.23.17 kubectl-1.23.17  --disableexcludes=kubernetes -y;
done

#查看kubeadm版本是否正确
kubeadm version 

#验证升级计划
kubeadm upgrade plan

#选择要升级到的目标版本
sudo kubeadm upgrade apply v1.23.17   

#其他master节点执行
for i in {2..3};do 
  ssh k8s-master$i sudo kubeadm upgrade node; #根据master节点hostname自调整
done

#重启kubelet
for i in {1..3};do
  ssh k8s-master$i "sudo systemctl daemon-reload && sudo systemctl restart kubelet"
done

#解除节点的保护,通过将节点标记为可调度,让其重新上线,
for i in {1..3};do
  sudo kubectl uncordon k8s-master$i;
done

#验证
kubectl get nodes
sleep 5s

#升级node节点

#腾空node节点
for i in {1..2};do  #根据node节点数量自调整
  sudo kubectl drain k8s-node$i --ignore-daemonsets --force;  #根据node节点hostname自调整
done

#升级 kubelet、kubectl、kubeadm
for i in {1..2};do
  ssh k8s-node$i sudo yum install kubeadm-1.23.17 kubelet-1.23.17 kubectl-1.23.17  --disableexcludes=kubernetes -y;
done

#升级本地的 kubelet 配置
for i in {1..2};do
ssh k8s-node$i sudo kubeadm upgrade node;
done

#重启kubelet
for i in {1..2};do 
  ssh k8s-node$i "sudo systemctl daemon-reload && sudo systemctl restart kubelet"
done

#等待kubelet重启成功
sleep 3s

#取消对节点的保护,通过将节点标记为可调度,让节点重新上线
for i in {1..2};do
  sudo kubectl uncordon k8s-node$i;
done

#等待节点上线
sleep 3s

#验证
kubectl get nodes
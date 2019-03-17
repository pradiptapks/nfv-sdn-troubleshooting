# Manual Routing NameSpace for troubleshooting

.--------.veth0       .--------.veth2       .--------.
| ns_snd |------------| ns_mid |------------| ns_rcv |
'--------'       veth1'--------'       veth3'--------'


veth0: 10.0.0.1/30
veth1: 10.0.0.2/30
veth2: 10.0.0.5/30
veth3: 10.0.0.6/30

veth0 belongs to ns_snd,
veth[1,2] belongs to ns_mid,
veth3 belongs to ns_rcv

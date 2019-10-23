from trex_stl_lib.api import *

class STLS1(object):

    def __init__ (self):
        self.fsize  = 64; # the size of the packet

    def create_stream (self, direction = 0):

        size = self.fsize - 4; # HW will add 4 bytes ethernet FCS
        if direction == 0:
            base_pkt =  Ether()/IP(src="16.0.0.1",dst="48.0.0.1")/UDP(dport=15,sport=1026)
        else:
            base_pkt =  Ether()/IP(src="16.1.0.1",dst="48.0.0.1")/UDP(dport=16,sport=1026)
        #pad = max(0, size - len(base_pkt)) * 'x'
        pad = (size- len(base_pkt)) * 'x'

        vm = STLScVmRaw( [ STLVmFlowVar(name="ip_src",
                                              min_value="16.0.0.0",
                                              max_value="18.0.0.254",
                                              size=4, op="random"),

                           STLVmWrFlowVar(fv_name="ip_src", pkt_offset= "IP.src" ),

                           STLVmFlowVar(name="ip_dst",
                                              min_value="192.168.0.0",
                                              max_value="192.168.254.254",
                                              size=4, op="random"),

                           STLVmWrFlowVar(fv_name="ip_dst", pkt_offset= "IP.dst" ),

                           STLVmFixIpv4(offset = "IP"), # fix checksum

                          ]
                       )


        return STLStream(
            packet =
                    STLPktBuilder(
                        pkt = base_pkt / pad,
                        vm = vm
                    ),
             mode = STLTXCont())

    def create_stats_stream (self, rate_pps = 1000, pgid = 7, direction = 0):

        size = self.fsize - 4; # HW will add 4 bytes ethernet FCS
        if direction == 0:
            base_pkt =  Ether()/IP(src="19.0.0.1",dst="48.0.0.1")/UDP(dport=15,sport=1026)
        else:
            base_pkt =  Ether()/IP(src="19.1.0.1",dst="48.0.0.1")/UDP(dport=16,sport=1026)
        pad = max(0, size - len(base_pkt)) * 'x'

        return STLStream(
            packet =
                    STLPktBuilder(
                        pkt = base_pkt / pad
                    ),
             mode = STLTXCont(pps = rate_pps),
             flow_stats = STLFlowLatencyStats(pg_id = pgid))
             #flow_stats = STLFlowStats(pg_id = pgid))

    def get_streams (self, fsize=64, direction = 0, **kwargs):
        self.fsize = fsize
        # create multiple streams, one stream per core...
        s = []
        xrange=range
        for i in xrange(8):
             s.append(self.create_stream(direction = direction))
        return s

# dynamic load - used for trex console or simulator
def register():
    return STLS1()

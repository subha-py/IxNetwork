################################################################################
# Version 1.0    $Revision: 1 $                                                #
#                                                                              #
#    Copyright ? 1997 - 2014 by IXIA                                           #
#    All Rights Reserved.                                                      #
#                                                                              #
#    Revision Log:                                                             #
#    10/2/2014 - Vlad Mihai - created sample                         #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
#                                LEGAL  NOTICE:                                #
#                                ==============                                #
# The following code and documentation (hereinafter "the script") is an        #
# example script for demonstration purposes only.                              #
# The script is not a standard commercial product offered by Ixia and have     #
# been developed and is being provided for use only as indicated herein. The   #
# script [and all modifications enhancements and updates thereto (whether      #
# made by Ixia and/or by the user and/or by a third party)] shall at all times #
# remain the property of Ixia.                                                 #
#                                                                              #
# Ixia does not warrant (i) that the functions contained in the script will    #
# meet the users requirements or (ii) that the script will be without          #
# omissions or error-free.                                                     #
# THE SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND AND IXIA         #
# DISCLAIMS ALL WARRANTIES EXPRESS IMPLIED STATUTORY OR OTHERWISE              #
# INCLUDING BUT NOT LIMITED TO ANY WARRANTY OF MERCHANTABILITY AND FITNESS FOR #
# A PARTICULAR PURPOSE OR OF NON-INFRINGEMENT.                                 #
# THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SCRIPT  IS WITH THE #
# USER.                                                                        #
# IN NO EVENT SHALL IXIA BE LIABLE FOR ANY DAMAGES RESULTING FROM OR ARISING   #
# OUT OF THE USE OF OR THE INABILITY TO USE THE SCRIPT OR ANY PART THEREOF     #
# INCLUDING BUT NOT LIMITED TO ANY LOST PROFITS LOST BUSINESS LOST OR          #
# DAMAGED DATA OR SOFTWARE OR ANY INDIRECT INCIDENTAL PUNITIVE OR              #
# CONSEQUENTIAL DAMAGES EVEN IF IXIA HAS BEEN ADVISED OF THE POSSIBILITY OF    #
# SUCH DAMAGES IN ADVANCE.                                                     #
# Ixia will not be required to provide any software maintenance or support     #
# services of any kind (e.g. any error corrections) in connection with the     #
# script or any part thereof. The user acknowledges that although Ixia may     #
# from time to time and in its sole discretion provide maintenance or support  #
# services for the script any such services are subject to the warranty and    #
# damages limitations set forth herein and will not obligate Ixia to provide   #
# any additional maintenance or support services.                              #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
# Description:                                                                 #
# The script creates one Custom TLV and adds it and another predefined TLV     #
# to the configuration.                                                        #
# Start/Stop protocols.                                                        #
# Module:                                                                      #
#    The sample was tested on an FlexAP10G16S module.                          #
# Software:                                                                    #
#    IxOS      6.80 EA                                                         #
#    IxNetwork 7.40 EA                                                         #
#                                                                              #
################################################################################

$:.unshift 'C:\samples\IxNetwork.rb'
require 'IxNetwork'

# create an instance of the IxNet class
@ixNet = IxNetwork.new

puts("Connecting to the server")
@ixNet.connect('10.200.115.203', '-setAttribute', 'strict', '-port', 8009, '-version', '7.40')

puts("Cleaning up IxNetwork...")
@ixNet.execute('newConfig')

# all objects are under root
root = @ixNet.getRoot()

puts("\nAdd virtual ports to configuration...")
vports = []
vports.push(@ixNet.add(root, 'vport'))
vports.push(@ixNet.add(root, 'vport'))
@ixNet.commit()

# get virtual ports
vports = @ixNet.getList(@ixNet.getRoot(), 'vport')

puts('Add chassis in IxNetwork...')
chassis = '10.200.115.151'
availableHardwareId = @ixNet.getRoot()+'availableHardware'
@ixNet.add(availableHardwareId, 'chassis', '-hostname', chassis)
@ixNet.commit()

puts("Assigning ports from " + chassis + " to "+ vports.to_s + " ...")
@ixNet.setAttribute(vports[0], '-connectedTo', '/availableHardware/chassis:"10.200.115.151"/card:4/port:1')
@ixNet.setAttribute(vports[1], '-connectedTo', '/availableHardware/chassis:"10.200.115.151"/card:4/port:2')
@ixNet.commit()

puts("Rebooting ports...")
jobs = Array.new
for vp in vports.each do
    jobs.push(@ixNet.setAsync().execute('resetPortCpu', vp))
end

# for j in jobs:
# puts j + ' ' + @ixNet.getResult(j)
# puts("Done... Ports are rebooted...")

sleep(5)
@ixNet.execute('clearStats')

# ######################## Add DHCP DGs ####################################### #

# adding topology with dhcp server

puts('# \n######## HOW TO create a topology with DGs and various layers ##### #')
puts('\n\nCreate first topology with DHCPServer...')

puts('\nAdd topology...')
@ixNet.add(root, 'topology')
puts('\nUse @ixNet.commit() to commit added child under root.')
@ixNet.commit()
puts('\nUse @ixNet.getList to get newly added child under root.')
topS = @ixNet.getList(root, 'topology')[0]

puts('Add virtual port to topology and change its name...')
@ixNet.setMultiAttribute(topS, '-vports', vports[0], '-name', 'DHCPserver')
@ixNet.commit()

puts('Add DeviceGroup for DHCPserver...')
@ixNet.add(topS, 'deviceGroup')
@ixNet.commit()
DG1 = @ixNet.getList(topS, 'deviceGroup')[0]

puts('Create the DHCPserver stack in this DeviceGroup...')
puts('Add Ethernet layer...')
@ixNet.add(DG1, 'ethernet')
@ixNet.commit()
eth1 = @ixNet.getList(DG1, 'ethernet')[0]

puts('Add IPv4 layer...')
@ixNet.add(eth1, 'ipv4')
@ixNet.commit()
ip1 = @ixNet.getList(eth1, 'ipv4')[0]

puts("Set IP layer to not resolve gateway IP.")
multivalue_gateway            = @ixNet.getAttribute(ip1, '-resolveGateway')
multivalue_gateway_sv        = @ixNet.getList(multivalue_gateway, 'singleValue')
multivalue_gateway_sv_value = @ixNet.setAttribute(multivalue_gateway_sv[0], '-value', 'false')
@ixNet.commit()

puts('Add DHCPServer layer...')
@ixNet.add(ip1, 'dhcpv4server')
@ixNet.commit()
dhcpServer = @ixNet.getList(ip1, 'dhcpv4server')[0]

puts('Change each Device Group multipliers on server topology...')
@ixNet.setAttribute(DG1, '-multiplier', 2)
@ixNet.commit()

# adding topology with dhcp client

puts('\n\nCreate first topology with DHCPclient...')

puts('Add topology...')
@ixNet.add(root, 'topology')
@ixNet.commit()
# the newly added topology is the second 'topology' object type under root
topC = @ixNet.getList(root, 'topology')[1]

puts('Add virtual port to topology and change its name...')
@ixNet.setMultiAttribute(topC, '-vports', vports[1], '-name', 'DHCP client')
@ixNet.commit()

puts('Add DeviceGroup for DHCPclient...')
@ixNet.add(topC, 'deviceGroup')
@ixNet.commit()
DG2 = @ixNet.getList(topC, 'deviceGroup')[0]

puts('Create the client stack in this DeviceGroup...')
puts('Add Ethernet layer...')
@ixNet.add(DG2, 'ethernet')
@ixNet.commit()
eth2 = @ixNet.getList(DG2, 'ethernet')[0]

puts('Add DHCPclient layer...')
@ixNet.add(eth2, 'dhcpv4client')
@ixNet.commit()
dhcpClient = @ixNet.getList(eth2, 'dhcpv4client')[0]

puts('Change each Device Group multipliers on server topology...')
@ixNet.setAttribute(DG2, '-multiplier', 10)
@ixNet.commit()

# #######################end Add DHCP DGs ################################## #

# ###################### Create a Custom TLV ################################ #
# ###################### Create a Custom TLV ################################ #
# ###################### Create a Custom TLV ################################ #

topC1 = @ixNet.getList(root, 'topology')[0]
topS1 = @ixNet.getList(root, 'topology')[1]

puts("Get global templates")
global_config = @ixNet.getList(root, 'globals')[0]
global_top = @ixNet.getList(global_config, 'topology')[0]
global_dhcp = @ixNet.getList(global_top, 'dhcpv4client')[0]
global_tlv_editor = @ixNet.getList(global_dhcp, 'tlvEditor')[0]
global_default_template = @ixNet.getList(@ixNet.getList(global_tlv_editor, 'defaults')[0], 'template')[0]

puts("Create a custom TLV")

puts("Add a new template")
new_template = @ixNet.add(global_tlv_editor,"template")
@ixNet.commit()

puts("Change the name")
@ixNet.setAttribute(new_template, "-name", "Test Template")
@ixNet.commit()

puts("Add a new TLV")
new_tlv = @ixNet.add(new_template,"tlv")
@ixNet.commit()

puts("Change the name")
@ixNet.setAttribute(new_tlv, "-name", "Test TLV")
@ixNet.commit()

puts("Modify Length")

new_tlv_length = @ixNet.getList(new_tlv, "length")[0]

puts("Modify Length Attributes")

puts("Set the name")
@ixNet.setAttribute(new_tlv_length, "-name", "Length")
@ixNet.commit()

puts('Change the Value for Length')
value_mv = @ixNet.getAttribute(new_tlv_length, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', '2')
@ixNet.commit()

puts("Modify type")

new_tlv_type = @ixNet.getList(new_tlv, "type")[0]

puts("Set the name")
@ixNet.setAttribute(new_tlv_type, "-name", "Type")
@ixNet.commit()

new_object = @ixNet.add(new_tlv_type, "object")
@ixNet.commit()

new_field = @ixNet.add(new_object, "field")
@ixNet.commit()

puts("Modify Field Attributes")

puts("Set the name")
@ixNet.setAttribute(new_field, "-name", "Code")
@ixNet.commit()

puts('Change the Code for Type')
value_mv = @ixNet.getAttribute(new_field, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', '150')
@ixNet.commit()

puts("Modify value")
new_value = @ixNet.getList(new_tlv, "value")[0]

puts("Edit Value Atributes")

puts("Set the name")
@ixNet.setAttribute(new_value, "-name", "Value")
@ixNet.commit()

puts("Add a container with two fields")
new_object = @ixNet.add(new_value, "object")
new_container = @ixNet.add(new_object, "container")
new_object_1 = @ixNet.add(new_container, "object")
new_object_2 = @ixNet.add(new_container, "object")

new_field_1 = @ixNet.add(new_object_1, "field")
new_field_2 = @ixNet.add(new_object_2, "field")
@ixNet.commit()

puts("Modify Field Attributes")

puts("Set the name")
@ixNet.setAttribute(new_field_1, "-name", "Field_1")
@ixNet.commit()

puts('Change the Value for Field_1')
value_mv = @ixNet.getAttribute(new_field_1, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', '4')
@ixNet.commit()

puts("Set the name")
@ixNet.setAttribute(new_field_1, "-name", "Field_2")
@ixNet.commit()

puts('Change the Value for Field_2')
value_mv = @ixNet.getAttribute(new_field_2, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', '5')
@ixNet.commit()

puts("Add a subTlv with two fields")

new_object = @ixNet.add(new_value, "object")
new_subtlv = @ixNet.add(new_object, "subTlv")
@ixNet.commit()

puts("Modify Length")

new_tlv_length = @ixNet.getList(new_subtlv, "length")[0]

puts("Modify Length Attributes")

puts("Set the name")
@ixNet.setAttribute(new_tlv_length, "-name", "Length")
@ixNet.commit()

puts('Change the Value for Length')
value_mv = @ixNet.getAttribute(new_tlv_length, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', '2')
@ixNet.commit()

puts("Modify type")

new_tlv_type = @ixNet.getList(new_subtlv, "type")[0]

puts("Set the name")
@ixNet.setAttribute(new_tlv_type, "-name", "Type")
@ixNet.commit()

new_object = @ixNet.add(new_tlv_type, "object")
@ixNet.commit()

new_field = @ixNet.add(new_object, "field")
@ixNet.commit()

puts("Modify Field Attributes")

puts("Set the name")
@ixNet.setAttribute(new_field, "-name", "Code")
@ixNet.commit()

puts('Change the Code for Type')
value_mv = @ixNet.getAttribute(new_field, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', '1')
@ixNet.commit()

puts('Adding the two fields')

new_value = @ixNet.getList(new_subtlv, "value")[0]

new_object_1 = @ixNet.add(new_value, "object")
new_object_2 = @ixNet.add(new_value, "object")

new_field_1 = @ixNet.add(new_object_1, "field")
new_field_2 = @ixNet.add(new_object_2, "field")
@ixNet.commit()

puts("Modify Field Attributes")

puts("Set the name")
@ixNet.setAttribute(new_field_1, "-name", "Field_1")
@ixNet.commit()

puts('Change the Value for Field_1')
value_mv = @ixNet.getAttribute(new_field_1, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', '4')
@ixNet.commit()

puts("Set the name")
@ixNet.setAttribute(new_field_2, "-name", "Field_2")
@ixNet.commit()

puts('Change the Value for Field_2')
value_mv = @ixNet.getAttribute(new_field_2, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', '5')
@ixNet.commit()

# ###################### Add TLVs to DCPv4 Client ############################## #
# ###################### Add TLVs to DCPv4 Client ############################## #
# ###################### Add TLVs to DCPv4 Client ############################## #

dhcpv4_tlvProfile = @ixNet.getList(dhcpClient, 'tlvProfile')[0]

puts("Getting default TLV")
dhcp_default_tlv = @ixNet.getList(dhcpv4_tlvProfile, 'defaultTlv')[0]

puts("Adding TLVs to the DHCP client")
prototype_custom_tlv_1_name = 'Test TLV'
prototype_predefined_tlv_1_name = '[12] Host Name'

global_predefined_tlv_1 = @ixNet.getFilteredList(global_default_template, 'tlv', '-name', prototype_predefined_tlv_1_name)
global_predefined_custom_tlv_1 = @ixNet.getFilteredList(new_template, 'tlv', '-name', prototype_custom_tlv_1_name)

predefined_tlv_1 = @ixNet.execute("copyTlv", dhcpv4_tlvProfile, global_predefined_tlv_1)
@ixNet.commit()
custom_tlv_1 = @ixNet.execute("copyTlv", dhcpv4_tlvProfile, global_predefined_custom_tlv_1)
@ixNet.commit()

messages = @ixNet.getAttribute(predefined_tlv_1, '-availableIncludeInMessages')
discover = messages[0]
request = messages[1]
decline = messages[2]
release = messages[3]

# ###################### Configure TLV values ############################## #
puts("Configure TLV values")

puts('Change the Value for TLV 18')
predefined_tlv_1_value = @ixNet.getList(predefined_tlv_1, 'value')[0]
predefined_tlv_1_value_object = @ixNet.getList(predefined_tlv_1_value, 'object')[0]
predefined_tlv_1_value_object_field = @ixNet.getList(predefined_tlv_1_value_object, 'field')[0]

value_mv = @ixNet.getAttribute(predefined_tlv_1_value_object_field, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', 'Custom_Value')
@ixNet.commit()

puts('Enable SubTlv 1 for the Default TLV, Option 55')
default_tlv_1_value = @ixNet.getList(dhcp_default_tlv, 'value')[0]
default_tlv_1_value_object = @ixNet.getList(predefined_tlv_1_value, 'object')[0]
default_tlv_1_value_object_field = @ixNet.getList(predefined_tlv_1_value_object, 'field')[0]
@ixNet.setAttribute(default_tlv_1_value_object_field, '-isEnabled', 'true')
@ixNet.commit()

puts('Change the Value for one of the fields in the sub Tlv of the custom created TLV')

custom_tlv_1_value = @ixNet.getList(custom_tlv_1, 'value')[0]
custom_tlv_1_value_object_1 = @ixNet.getList(custom_tlv_1_value, 'object')[1]
custom_tlv_1_value_object_1_subTlv = @ixNet.getList(custom_tlv_1_value_object_1, 'subTlv')[0]

subTlv_value = @ixNet.getList(custom_tlv_1_value_object_1_subTlv, 'value')[0]
subTlv_value_object_1 = @ixNet.getList(subTlv_value, 'object')[0]
custom_tlv_1_value_object_1_field = @ixNet.getList(subTlv_value_object_1, 'field')[0]

value_mv = @ixNet.getAttribute(custom_tlv_1_value_object_1_field, '-value')
@ixNet.setAttribute(value_mv, '-pattern', 'singleValue')
@ixNet.commit()
value_mv_singleValue = @ixNet.getList(value_mv, 'singleValue')[0]
@ixNet.setMultiAttribute(value_mv_singleValue, '-value', '20')
@ixNet.commit()

puts("Set Include in Messages")

@ixNet.setAttribute(predefined_tlv_1, '-includeInMessages', [discover,request,release])
@ixNet.setAttribute(dhcp_default_tlv, '-includeInMessages', [discover,request,decline])
@ixNet.setAttribute(custom_tlv_1, '-includeInMessages', [request, release])
@ixNet.commit()

sleep(30)
# ################################### Dynamics ############################### #
puts('# \n####################### HOW TO start/stop/restart protocols ####### #')
#starting topologies
puts("\n\nStarting the topologies using @ixNet.execute('start', topS)")
@ixNet.execute('start', topS1)
sleep(0.5)
@ixNet.execute('start', topC1)

# wait for all sessions to start
while ((@ixNet.getAttribute(dhcpServer, '-stateCounts')[1]).to_i + (@ixNet.getAttribute(dhcpClient, '-stateCounts')[1]).to_i) > 0 do
    puts('\ndhcpServer layer: Sessions TOTAL/ NOT STARTED/ DOWN/ UP: ' + @ixNet.getAttribute(dhcpServer, '-stateCounts').to_s)
    puts('dhcpClient layer: Sessions TOTAL/ NOT STARTED/ DOWN/ UP: ' + @ixNet.getAttribute(dhcpClient, '-stateCounts').to_s)
    puts('Waiting for all sessions to be started...')
    sleep(3)
end
puts('dhcpServer layer: Sessions TOTAL/ NOT STARTED/ DOWN/ UP: ' + @ixNet.getAttribute(dhcpServer, '-stateCounts').to_s)
puts('dhcpClient layer: Sessions TOTAL/ NOT STARTED/ DOWN/ UP: ' + @ixNet.getAttribute(dhcpClient, '-stateCounts').to_s)

puts('All sessions started...')
sleep(15)

puts('Learned information - Negotiated client addresses:')
puts(@ixNet.getAttribute(dhcpClient, '-discoveredPrefix').to_s)

puts("\n\nRenewing the client leases using @ixNet.execute('renew', dhcpClient)")
@ixNet.execute('renew', dhcpClient)

#reading stats

sleep(20)
puts("\n\nRefreshing NGPF statistics views can be done from API using the following exec command: @ixNet.execute('refresh', '__allNextGenViews')")
@ixNet.execute('refresh', '__allNextGenViews')
sleep(3)

mv          = @ixNet.getList(@ixNet.getRoot(), 'statistics')[0]
view_list   = @ixNet.getList(mv, 'view')
puts('\n\nAvailable statistics views are :\n ' + view_list.to_s)

#stopping per topology

puts('\n\nStop topologies...')
@ixNet.execute('stop',topC)

sleep(10)
@ixNet.execute('stop',topS)

puts("\n\nCleaning up IxNetwork...")
@ixNet.execute('newConfig')
@ixNet.disconnect()
puts("Done: IxNetwork session is closed...")

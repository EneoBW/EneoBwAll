#
=begin
    #   All informations for any db environment to trigger it
    #   VRP: 1-1-1 <122312-0800>
    #       For each file :
    #       if check file   => store True on auths
    #       if !check file  => store false on auths
    #   Databases :
    #       excBugs
=end
class CliNotion_Bug
#********************

#
#Variables
#+++++++++
    @@dbs     = {
        'db'=>  {
                'dbname'=>      'excBugs',
                'dbprefix'=>    'BUG',
                'dbid'=>        'c3e9979d59cc44ad84480c18d1142c5b', #https://www.notion.so/eneobw/c3e9979d59cc44ad84480c18d1142c5b?v=01632512cc0c4ef5a2240f3184b98710&pvs=4
                'dbintegr'=>    'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS',    #EneoBW
                'dbfields'=>    [
                                'Référence'
                                ],       
                }
        }
#
#Functions
#+++++++++

    def initialize()
    #=============
        #new instance
        #INP:   
        #OUT:   

        return true
    end #<def>

    def load()
    #=======
        #return dbvalues
        #INP:   
        #OUT:   {dbname=>,dbprefix=>,dbid=>,dbintegr=>,dbfields=>}
        return @@dbs
    end #<def>
    #
end #<Module>   
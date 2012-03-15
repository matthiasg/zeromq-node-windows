{
  'targets': [
    {
      'target_name': 'zeromq',
      'product_name': 'zeromq',
      'sources': [ 'src/bindings.cc' ],
		  'conditions': [
      [ 'OS=="win"', {
          'defines': [
            'PLATFORM="win32"',
            '_LARGEFILE_SOURCE',
            '_FILE_OFFSET_BITS=64',
            '_WINDOWS',
            'Configuration=Release',
            'BUILDING_NODE_EXTENSION'
          ],
          'libraries': [ 
              'libzmq.lib',
          ],
          'include_dirs': [
            'deps\\include\\',
            'deps\\zmq\\',
          ],         
           'msvs_settings': {
            'VCLinkerTool': {
              'AdditionalLibraryDirectories': [
                '..\\deps\\zmq'
              ],
            },
          },
        },
      ], # windows
      ] # condition
    } # targets
  ]
}

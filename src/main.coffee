root = window ? exports

root.pick = (arr) -> arr[Math.floor Math.random() * arr.length]
root.isValid = (value) -> !isNaN(value) and isFinite(value)
root.seed = 0xCAFEBABE

# JS Implementation of MurmurHash3
# 
# @author <a href="mailto:gary.court@gmail.com">Gary Court</a>
# @see http://github.com/garycourt/murmurhash-js
# @author <a href="mailto:aappleby@gmail.com">Austin Appleby</a>
# @see http://sites.google.com/site/murmurhash/
# 
# @param {obj} a Javascript object
# @param {number} seed Positive integer only
# @return {number} 32-bit positive integer hash
root.hash = (obj) ->
  key = JSON.stringify obj

  remainder = key.length & 3
  bytes = key.length - remainder
  h1 = root.seed
  c1 = 0xcc9e2d51
  c2 = 0x1b873593
  i = 0

  while i < bytes
    k1 = ((key.charCodeAt(i) & 0xff))         |
         ((key.charCodeAt(++i) & 0xff) << 8)  |
         ((key.charCodeAt(++i) & 0xff) << 16) |
         ((key.charCodeAt(++i) & 0xff) << 24)
    ++i

    k1 = ((((k1 & 0xffff) * c1) + ((((k1 >>> 16) * c1) & 0xffff) << 16))) & 0xffffffff
    k1 = (k1 << 15) | (k1 >>> 17)
    k1 = ((((k1 & 0xffff) * c2) + ((((k1 >>> 16) * c2) & 0xffff) << 16))) & 0xffffffff

    h1 ^= k1
    h1 = (h1 << 13) | (h1 >>> 19)
    h1b = ((((h1 & 0xffff) * 5) + ((((h1 >>> 16) * 5) & 0xffff) << 16))) & 0xffffffff
    h1 = (((h1b & 0xffff) + 0x6b64) + ((((h1b >>> 16) + 0xe654) & 0xffff) << 16))

  k1 = 0

  if remainder > 2
    k1 ^= (key.charCodeAt(i + 2) & 0xff) << 16

  if remainder > 1
    k1 ^= (key.charCodeAt(i + 1) & 0xff) << 8

  if remainder > 0
    k1 ^= (key.charCodeAt(i) & 0xff)

  k1 = (((k1 & 0xffff) * c1) + ((((k1 >>> 16) * c1) & 0xffff) << 16)) & 0xffffffff
  k1 = (k1 << 15) | (k1 >>> 17)
  k1 = (((k1 & 0xffff) * c2) + ((((k1 >>> 16) * c2) & 0xffff) << 16)) & 0xffffffff
  h1 ^= k1

  h1 ^= key.length

  h1 ^= h1 >>> 16
  h1 = (((h1 & 0xffff) * 0x85ebca6b) + ((((h1 >>> 16) * 0x85ebca6b) & 0xffff) << 16)) & 0xffffffff
  h1 ^= h1 >>> 13
  h1 = ((((h1 & 0xffff) * 0xc2b2ae35) + ((((h1 >>> 16) * 0xc2b2ae35) & 0xffff) << 16))) & 0xffffffff
  h1 ^= h1 >>> 16
  h1 >>> 0

if require? and Buffer?
  try
    XXHash = require 'xxhash'
    root.hash = (obj) ->
      str = new Buffer JSON.stringify obj
      XXHash.hash str, root.seed

class root.Reservoir

  constructor: (opts) ->
    unless opts.library
      throw "Error, missing library"
    @library = opts.library
    @reservoir = opts.existing ? {}
    @max_size = opts.max_size ? 1000

  ###
  generate a random node, returning its unique id
  nodes with same source code will have the same id
  note: id unique id is computed using the hash
  ###
  generate: ->  
    arity = Math.floor Math.random() * @library.length
    functions = @library[@arity]
    name = root.pick Object.keys functions
    reservoirKeys = @list()
    nb_inputs = if !reservoirKeys.length then 0 else arity
    node = 
      arity: arity
      name: name
      code: functions[name]
      inputs: for i in [0...nb_inputs]
        root.pick reservoirKeys
    id = root.hash(node).toString()
    @reservoir[id] = node
    id

  ###
  recursively evaluate a node graph
  we take the cached values, so we never do more calls than the total number of elements
  ###
  run: (id) =>
    node = @get id
    return unless node?
    return node.cache if node.cache?
    value = node.code (@run n for n in node.inputs)...
    if root.isValid value
      node.cache = value
      value
    else
      @delete id
      return

  refill: ->
    len = @size()
    for i in [len...@max_size]
      id = @generate()
      while not root.isValid @run id
        id = @generate()
    @

  ###
  warm the reservoir by executing each function and storing the result in a cache
  bad functions will be removed
  ###
  warm: -> @run id for id in @list() ; @
      
  ###
  cool off the reservoir by flushing every cached value
  ###
  flush: -> delete node['cache'] for _, node of @reservoir ; @

  ###
  check if a function exists in the database
  ###
  has: (id) -> id of @reservoir

  ###
  fetch a node
  ###
  get: (id) -> @reservoir[id]

  ###
  delete a node
  ###
  delete: (id) -> delete @reservoir[id]

  ###
  pick a random function ID
  ###
  pick: -> root.pick @list()

  ###
  returns the current reservoir size
  ###
  size: -> @list().length

  ###
  list all reservoir IDs (warning: can be large)
  ###
  list: -> Object.keys @reservoir

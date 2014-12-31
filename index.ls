require! <[fs styl path]>

mkdir-recurse = (f) ->
  if fs.exists-sync f => return
  parent = path.dirname(f)
  if !fs.exists-sync parent => mkdir-recurse parent
  fs.mkdir-sync f

styl-tree = do
  down-hash: {}
  up-hash: {}
  parse: (filename) ->
    dir = path.dirname(filename)
    ret = fs.read-file-sync filename .toString!split \\n .map(-> /^ *@import (.+)/.exec it)filter(->it)map(->it.1)
    ret = ret.map -> path.join(dir, it.replace(/(\.styl)?$/, ".styl"))
    @down-hash[filename] = ret
    for it in ret => if not (filename in @up-hash.[][it]) => @up-hash.[][it].push filename
  find-root: (filename) ->
    work = [filename]
    ret = []
    while work.length > 0
      f = work.pop!
      if @up-hash.[][f].length == 0 => ret.push f
      else work ++= @up-hash[f]
    ret

styl-recursively = (src,des,config,rel="") ->
  files = _style-recursively src, des, config, rel
  files.map -> [src, it.replace(src, des)]
  for file in files =>
    mkdir-recurse path.dirname file.1
    content = fs.read-file-sync file.0 .toString!
    fs.write-file-sync file.1, styl(content, config)toString!

_styl-recursively = (src,des,config,rel="") ->
  src-full = path.join(src, rel)
  des-full = path.join(des, rel)
  
  files = fs.readdir-sync src-full .map (f) -> [
      path.join(src-full, f)
      path.join(des-full, f.replace(/\.styl/, ".css"))
      path.join(rel, f)
  ]
  ret = []
  for file in files =>
    if fs.lstat-sync file.0 .is-directory! => 
      ret ++= _styl-recursively src, des, config, file.2
      continue
    if /\.styl/.exec file.0 => 
      styl-tree.parse file.0
      srcs = sass-tree.find-root file.0
      ret ++= srcs
  return ret

# example: styl-recursively \src, \static, {hello: 456}
module.exports = styl-recursively

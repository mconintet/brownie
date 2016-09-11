browserify = require('browserify')
gulp = require('gulp')
source = require('vinyl-source-stream')
buffer = require('vinyl-buffer')
uglify = require('gulp-uglify')
sourcemaps = require('gulp-sourcemaps')
gutil = require('gulp-util')
size = require('gulp-size')
gzip = require('gulp-gzip')

task 'build', 'build', (options) ->
  gutil.log gutil.colors.blue 'building...'
  browserify({
    entries: './src/main.coffee',
    extensions: ['.coffee'],
    transform: ['coffeeify'],
    debug: true
  }).bundle()
  .on 'end', ()->
    gutil.log gutil.colors.blue 'browserify done'
  .pipe source 'brownie.min.js'
  .pipe gulp.dest './dist/js/'
  .pipe buffer()
  .pipe sourcemaps.init loadMaps: true
  .pipe uglify()
  .on 'error', gutil.log
  .pipe sourcemaps.write './'
  .pipe size title: 'coffee → javascript', showFiles: yes, gzip: no
  .pipe gulp.dest './dist/js/'
  .pipe gzip()
  .pipe gulp.dest './dist/js/'
  .on 'end', () ->
    gutil.log gutil.colors.blue 'build done'
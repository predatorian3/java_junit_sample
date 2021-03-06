# JRuby has Ant already included in its STDLIB so you can use it out of the box.
# However, I would still recommend having Ant installed, in your PATH and
# the Ant Tasks you're using in the Ant Lib folder.
require 'ant'

PROJECT_NAME = 'SampleClass'.freeze
MAIN_SRC_DIR = 'src/main'.freeze
TEST_SRC_DIR = 'src/test'.freeze
MAIN_CLASS = 'sample.SampleClass'.freeze
BUILD_DIR = 'build'.freeze
CLASSES_DIR = "#{BUILD_DIR}/classes".freeze
JARS_DIR = "#{BUILD_DIR}/jars".freeze
TESTS_CLASSES_DIR = "#{CLASSES_DIR}/test".freeze
DOCS_DIR = 'docs'.freeze

# Default task when rake is ran without any arguments.
task default: ['java:clean', 'java:compile']

namespace :java do
  desc 'Install Java Project Dependencies.'
  task :deps do
    ant.mkdir(dir: 'lib')
    ant.get(
      src: 'http://search.maven.org/remotecontent?filepath=junit/junit/4.12/junit-4.12.jar',
      dest: 'lib/junit-4.12.jar'
    )
    ant.get(
      src: 'http://search.maven.org/remotecontent?filepath=org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar',
      dest: 'lib/hamcrest-core.1.3.jar'
    )
  end

  task setup_test: ['java:deps'] do
    ant.path(id: 'classpath.test') do
      pathelement(location: 'lib/junit-4.12.jar')
      pathelement(location: 'lib/hamcrest-core.1.3.jar')
      pathelement(location: "#{CLASSES_DIR}/main")
    end
  end

  task :setup_compile do
    ant.path(id: 'classpath') do
      fileset(dir: '.')
    end
  end

  desc 'Clean up generated files.'
  task :clean do
    ant.delete(dir: BUILD_DIR)
    ant.delete(dir: 'docs')
  end

  desc 'Compile the Java Project.'
  task compile: ['java:setup_compile'] do
    ant.mkdir(dir: "#{CLASSES_DIR}/main")
    ant.javac(
      includeantruntime: 'false',
      srcdir: MAIN_SRC_DIR,
      destdir: "#{CLASSES_DIR}/main"
    )
  end

  desc 'Create the Java Project JAR.'
  task jar: ['java:setup_compile', 'java:compile'] do
    ant.jar(destfile: "#{JARS_DIR}/#{PROJECT_NAME}.jar", basedir: "#{CLASSES_DIR}/main") do
      manifest do
        attribute(name: 'Main-Class', value: MAIN_CLASS)
      end
    end
  end

  desc 'Compile the JUnit Tests.'
  task junit_compile: ['java:setup_test'] do
    ant.mkdir(dir: TESTS_CLASSES_DIR)
    ant.javac(srcdir: TEST_SRC_DIR, destdir: TESTS_CLASSES_DIR, includeantruntime: 'false') do
      classpath(refid: 'classpath.test')
    end
  end

  desc 'Run the JUnit Tests.'
  task junit_test: ['java:setup_test', 'java:junit_compile'] do
    ant.junit(printsummary: 'on', haltonfailure: 'yes', fork: 'true') do
      classpath do
        path(refid: 'classpath.test')
        pathelement(location: "#{CLASSES_DIR}/main")
        pathelement(location: "#{CLASSES_DIR}/test")
      end
      formatter(type: 'brief', usefile: 'false')
      batchtest do
        fileset(dir: TEST_SRC_DIR, includes: '**/*Test.java')
      end
    end
  end

  desc 'Run the Java Project Class.'
  task run_class: ['java:setup_compile', 'java:compile'] do
    ant.java(fork: 'true',
             classpath: "#{CLASSES_DIR}/main",
             failonerror: 'yes',
             dir: CLASSES_DIR,
             classname: MAIN_CLASS)
  end

  desc 'Run the Java Project JAR.'
  task run_jar: ['java:setup_compile', 'java:jar'] do
    ant.java(fork: 'true', classname: MAIN_CLASS) do
      classpath do
        path(refid: 'classpath')
        path(location: "#{JARS_DIR}/#{PROJECT_NAME}.jar")
      end
    end
  end

  desc 'Generate the JavaDocs.'
  task doc: ['java:setup_compile'] do
    ant.javadoc(sourcepath: MAIN_SRC_DIR, destdir: DOCS_DIR)
  end

  desc 'Run JRuby File.'
  task run_jruby: ['java:compile'] do
    sh 'jruby jruby_junit_example_01.rb'
  end
end

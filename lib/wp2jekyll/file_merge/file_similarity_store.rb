require 'yaml'
require 'fileutils'

module Wp2jekyll

    class FileSimilarityStore
        include DebugLogger

        @@store_dir = "#{ENV['HOME']}/.wp2jekyll/usr/#{ENV['USER']}"
        @@store_fp = "#{@@store_dir}/file_similarity_store.yaml"
        @@yaml_hash = {}

        SAV_EVERY_N_RECORD = 50
        @@record_counter = 0

        def self.init(fp = '')
            if File.exist? fp
                @@store_fp = fp
            end

            if !File.exist? @@store_fp
                FileUtils.touch @@store_fp
            end

            @@yaml_hash = YAML.load(File.read(@@store_fp))

            if !@@yaml_hash
                @@yaml_hash = {}
            end
        end

        def self.save
            File.write(@@store_fp, @@yaml_hash.to_yaml)
        end

        self.init()

        def initialize(fp = '')
            if (fp != @@store_fp)
                self.class.save
                self.class.init(fp)
            end
            # ObjectSpace.define_finalizer(self,
            #     self.class.method(:save).to_proc)
        end

        def record_similarity(a,b,similarity)
            if nil == @@yaml_hash[a] then
                @@yaml_hash[a] = {
                    b => {
                        :similarity => similarity,
                        :timestamp => Time.now
                    }
                }
            else
                @@yaml_hash[a][b] = {
                    :similarity => similarity,
                    :timestamp => Time.now
                }
            end

            # @@logger.debug "record #{a}, #{b}, #{similarity}"
            @@record_counter += 1
            if @@record_counter > SAV_EVERY_N_RECORD
                # @@logger.debug "save cache".red
                self.class.save
                @@record_counter = 0
            end
        end

        # @ctime: last ctime of a, b
        def get_similarity(a,b, ctime:)
            if nil != @@yaml_hash[a]
                if nil != @@yaml_hash[a][b]
                    if @@yaml_hash[a][b][:timestamp] > ctime # a and b is not changed
                        # @@logger.debug "hit"
                        @@yaml_hash[a][b][:similarity]
                    end
                end
            else
                if nil != @@yaml_hash[b]
                    if nil != @@yaml_hash[b][a]
                        if @@yaml_hash[b][a][:timestamp] > ctime # a and b is not changed
                            # @@logger.debug "hit"
                            @@yaml_hash[b][a][:similarity]
                        end
                    end
                else
                    # @@logger.debug "miss"
                    nil
                end
            end
        end

    end

end
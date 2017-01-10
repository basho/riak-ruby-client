# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'riak/util/translation'

module Riak
  # Raised when a tombstone object (i.e. has vclock, but no rcontent values) is
  # stored or manipulated as if it had a single value.
  class Tombstone < StandardError
    include Util::Translation

    def initialize(robject)
      super t('tombstone_object', :robject => robject.inspect)
    end
  end
end

#   This gdb script is Android-customized based on
#   http://www.yolinux.com/TUTORIALS/src/dbinit_stl_views-1.03.txt.
#   Contact: younghuster@163.com
#
#   STL GDB evaluators/views/utilities - 1.03
#
#   The new GDB commands:
#           are entirely non instrumental
#           do not depend on any "inline"(s) - e.g. size(), [], etc
#       are extremely tolerant to debugger settings
#
#   This file should be "included" in .gdbinit as following:
#   source stl-views.gdb or just paste it into your .gdbinit file
#
#   The following STL containers are currently supported:
#
#       std::vector<T> -- via pvector command
#       std::list<T> -- via plist or plist_member command
#       std::map<T,T> -- via pmap or pmap_member command
#       std::multimap<T,T> -- via pmap or pmap_member command
#       std::set<T> -- via pset command
#       std::multiset<T> -- via pset command
#       std::deque<T> -- via pdequeue command
#       std::stack<T> -- via pstack command
#       std::queue<T> -- via pqueue command
#       std::priority_queue<T> -- via ppqueue command
#       std::bitset<n> -- via pbitset command
#       std::string -- via pstring command
#       std::widestring -- via pwstring command
#
#   The end of this file contains (optional) C++ beautifiers
#   Make sure your debugger supports $argc
#
#   Simple GDB Macros writen by Dan Marinescu (H-PhD) - License GPL
#   Inspired by intial work of Tom Malnar,
#     Tony Novac (PhD) / Cornell / Stanford,
#     Gilad Mishne (PhD) and Many Many Others.
#   Contact: dan_c_marinescu@yahoo.com (Subject: STL)
#
#   Modified to work with g++ 4.3 by Anders Elton
#   Also added _member functions, that instead of printing the entire class in map, prints a member.


#-------------------------------------------------------------
#                        Android libc++
#-------------------------------------------------------------

#
# std::list<T>
#

define pList
	if $argc == 0
		help pList
	else
		set $head = &$arg0
		set $current = $arg0.__end_.__next_
                #p /x $head
		#set $alloc_size = $arg0.__size_alloc_.__first_
		set $size = 0
                set $pointer_size = sizeof($current)

		# dump memory of std::list<T>
                printf "\n- dump memory of std::list<T>(%d bytes):\n", $pointer_size * 3
                if $pointer_size == 4
			x /3xw $head
                else
			x /3xg $head
                end

		# traverse std::list<T>
		if $argc >= 2
			printf "\n- dump elements of std::list<T>:\n"
		end
		while $current != $head
			#p /x $current
			if $argc == 2
				printf "elem[%-3u]: ", $size
				p *($arg1*)((unsigned long)$current + $pointer_size * 2)
			end
			if $argc == 3
				if $size == $arg2
					printf "elem[%u]: ", $size
					p *($arg1*)((unsigned long)$current + $pointer_size * 2)
					loop_break
				end
			end
			set $current = $current->__next_
			set $size++
		end

		printf "\n- Misc:\n"
		printf "std::list<T> size = %u \n", $size
		if $argc == 1
			printf "pList "
			whatis $arg0
			printf "Use pList <variable_name> <element_type> to see the elements in the list.\n"
		end
	end
end

document pList
	Prints Android std::list<T> information.
	Syntax: pList <list> <T> <idx>: Prints list size, if T defined all elements or just element at idx
	Examples:
	pList 'art::Runtime::instance_'->thread_list_->list_                     - prints list size and definition
	pList 'art::Runtime::instance_'->thread_list_->list_  'art::Thread'*     - prints all elements and list size
	pList 'art::Runtime::instance_'->thread_list_->list_  'art::Thread'* 0   - prints the first element in the list (if exists) and list size
end

#
# std::vector<T>
#

define pVector
	if $argc == 0
		help pVector
	else
		set $begin = $arg0.__begin_
		set $size = $arg0.__end_ - $begin
		set $size_max = $size - 1
		set $capacity = $arg0.__end_cap_.__first_ - $begin
		set $pointer_size = sizeof($begin)

		# dump memory of std::vector<T>
		printf "\n- dump memory of std::vector<T>(%d bytes):\n", $pointer_size * 3
		if $pointer_size == 4
			x /3xw &$arg0
		else
			x /3xg &$arg0
		end

		# traverse std::vector<T>
		printf "\n- dump elements of std::vector<T>:\n"
	end

	if $argc == 1
		set $i = 0
		while $i < $size
			printf "elem[%-2u]: ", $i
			p $begin[$i]
			set $i++
		end
	end

	if $argc == 2
		set $idx = $arg1
		if $idx < 0 || $idx > $size_max
			printf "idx is not in acceptable range: [0..%u].\n", $size_max
		else
			printf "elem[%u]: ", $idx
			p $begin[$idx]
		end
	end

	if $argc == 3
		set $start_idx = $arg1
		set $stop_idx = $arg2
		if $start_idx > $stop_idx
			set $tmp_idx = $start_idx
			set $start_idx = $stop_idx
			set $stop_idx = $tmp_idx
		end
		if $start_idx < 0 || $stop_idx < 0 || $start_idx > $size_max || $stop_idx > $size_max
			printf "idx1, idx2 are not in acceptable range: [0..%u].\n", $size_max
		else
			set $i = $start_idx
			while $i <= $stop_idx
				printf "elem[%u]: ", $i
				p $begin[$i]
				set $i++
			end
		end
	end

	if $argc > 0
		printf "\n- Misc:\n"
		printf "Vector size = %u\n", $size
		printf "Vector capacity = %u\n", $capacity
		printf "Element "
		whatis $begin
	end
end

document pVector
	Prints Android std::vector<T> information.
	Syntax: pVector <vector> <idx1> <idx2>
	Note: idx, idx1 and idx2 must be in acceptable range [0..<vector>.size()-1].
	Examples:
	pVector 'art::Runtime::instance_'->heap_->boot_image_spaces_       - Prints vector content, size, capacity and T typedef
	pVector 'art::Runtime::instance_'->heap_->boot_image_spaces_ 0     - Prints element[0] from vector
	pVector 'art::Runtime::instance_'->heap_->boot_image_spaces_ 0 2   - Prints element[0] to element[2] from vector
end

#
# std::string
#

define pString
	if $argc == 0
		help pString
	else
		set $pointer_size = sizeof($arg0.__r_.__first_.__l.__data_)
		printf "\n- dump memory of std::string(%d bytes):\n", $pointer_size * 3
		if $pointer_size == 4
			x /3xw &$arg0
		else
			x /3xg &$arg0
		end

		printf "\n- dump elements of std::string:\n"
		if $arg0.__r_.__first_.__l.__size_ == 0
			printf "Null string\n"
		else

			printf "String \t\t\t= \"%s\"\n", $arg0.__r_.__first_.__l.__data_
		end

		printf "\n- Misc:\n"
		printf "String size/length \t= %u\n", $arg0.__r_.__first_.__l.__size_
		printf "String capacity \t= %u\n", $arg0.__r_.__first_.__l.__cap_
	end
end

document pString
	Prints Android std::string information.
	Syntax: pString <string>
	Example:
	pString 'art::Runtime::instance_'->boot_class_path_string_   - Prints content, size/length and capacity of string boot_class_path_string_
end

#-------------------------------------------------------------
#                        Android ART
#-------------------------------------------------------------

define GetAndroidOS
	set $image=('art::gc::space::ImageSpace' *)('art::Runtime::instance_'->heap_->boot_image_spaces_.__begin_[0])
	set $begin=(unsigned char *)$image->begin_
	# version[4] = {'0', '2', '9', 0}
	set $image_version = ($begin[4] - '0') * 100 + ($begin[5] - '0') * 10 + ($begin[6] - '0')
	#p /d $image_version

	set $Android_OS = 'K'
	# Android 7.0/7.1
	if ($image_version == 29) || ($image_version == 30)
		set $Android_OS = 'N'
	end

	# Android 8.0/8.1
	if ($image_version == 43) || ($image_version == 46)
		set $Android_OS = 'O'
	end

	#p /c $Android_OS
end

#
# java_vm_ is a JavaVMExt* data structure in art::Runtime.
#
define pJavaVMExt
	# Android N: JavaVMExt* java_vm_;
	# Android O: std::unique_ptr<JavaVMExt> java_vm_
	GetAndroidOS
	if $Android_OS == 'N'
		p /x *'art::Runtime::instance_'->java_vm_
	end

	if $Android_OS == 'O'
		p /x *('art::JavaVMExt' *)('art::Runtime::instance_'->java_vm_.__ptr_.__first_)
	end
end

#
# list_ is a std::list data structure.
#
define pThreadList
	set $head = &'art::Runtime::instance_'->thread_list_->list_
	#p /x $head

	set $current = $head->__end_.__next_
	#p /x $current

	set $pointer_size = sizeof($current)
	while $current != $head
		set $t = *('art::Thread' **)((unsigned long)$current + $pointer_size * 2)
		#p /x $t
		set $name = $t->tlsPtr_.name->__r_.__first_.__l.__data_
		printf "Thread[tid = %-5d, name = %-40s]: flag = %d, state = %d\n", $t->tls32_.tid, $name, \
		$t->tls32_.state_and_flags.as_struct.flags, $t->tls32_.state_and_flags.as_struct.state
		set $current = $current->__next_
	end
end

#
# boot_image_spaces_ is a std::vector data structure.
#
define pBootImageSpaces
	set $boot_image_spaces = 'art::Runtime::instance_'->heap_->boot_image_spaces_
	set $begin = $boot_image_spaces.__begin_
	set $size = $boot_image_spaces.__end_ - $begin

	# traverse the std::vector<T>
	set $i = 0
	while $i < $size
		p /x *$begin[$i]
		set $i++
	end

	printf "std::vector<> size: %u\n", $size
end

#
# regions_ is a std::unique_ptr<Region[]> data structure(From Android 8.0).
#
define pRegionSpace
	set $size = 256
	set $size_max = $size - 1
	set $regions = ('art::gc::space::RegionSpace::Region' *)'art::Runtime::instance_'->heap_->concurrent_copying_collector_->region_space_->regions_.__ptr_.__first_

	if $argc == 0
		set $i = 0
		while $i < $size
			p $regions[$i]
			set $i++
		end
	end

	if $argc == 1
		set $idx = $arg0
		if $idx < 0 || $idx > $size_max
			printf "idx is not in acceptable range: [0..%u].\n", $size_max
		else
			p $regions[$idx]
		end
	end

	if $argc == 2
		set $start_idx = $arg0
		set $stop_idx = $arg1
		if $start_idx > $stop_idx
			set $tmp_idx = $start_idx
			set $start_idx = $stop_idx
			set $stop_idx = $tmp_idx
		end
		if $start_idx < 0 || $stop_idx < 0 || $start_idx > $size_max || $stop_idx > $size_max
			printf "idx1, idx2 are not in acceptable range: [0..%u].\n", $size_max
		else
			set $i = $start_idx
			while $i <= $stop_idx
				p $regions[$i]
				set $i++
			end
		end
	end
end

document pRegionSpace
	Prints Android ART region_space_->regions_ information.
	Syntax: pRegionSpace <idx>
	Examples:
	pRegionSpace                    - prints all regions
	pRegionSpace idx                - prints the specified regions[idx]
	pRegionSpace begin end          - prints the specified regions[begin] to regions[end]
end

#
# Print art::Runtime::instance_->class_linker_->dex_caches_ data structure.
#
define pDexCaches
	set $head = &'art::Runtime::instance_'->class_linker_->dex_caches_

	set $current = $head->__end_.__next_

	set $pointer_size = sizeof($current)
	set $i = 0
	while $current != $head
		set $dex = (('art::ClassLinker::DexCacheData' *)((unsigned long)$current + $pointer_size * 2))->dex_file
		printf "DexFile location[%-2u] = \"%s\"\n", $i++, $dex->location_.__r_.__first_.__l.__data_
		set $current = $current->__next_
	end
end

document pDexCaches
	Prints Android art::Runtime::instance_->class_linker_->dex_caches_ information.
	Syntax: pDexCaches
	Examples:
	pDexCaches
end
#
# Print art::DexFile data structure.
#
define pDexFile
	set $dex = ('art::DexFile' *)$arg0
	p /x *$dex
	printf "\nDexFile location = \"%s\"\n", $dex->location_.__r_.__first_.__l.__data_
end

document pDexFile
	Prints Android art::DexFile information.
	Syntax: pDexFile <dex>   dex is the address of art::DexFile object
	Examples:
	pDexFile 0xad0d5040    - prints all information about art::DexFile at 0xad0d5040
end

#
# Print art::ArtMethod data structure.
#
define pArtMethod
	set $method = ('art::ArtMethod' *)$arg0
	p /x *$method
end

document pArtMethod
	Prints Android art::ArtMethod information.
	Syntax: pArtMethod <method>   method is the address of art::ArtMethod object
	Examples:
	pArtMethod 0x6fbad488    - prints all information about art::ArtMethod at 0x6fbad488
end

#
# Print art::mirror::Array data structure.
#
define pMirrorArray
	set $array = ('art::mirror::Array' *)$arg0
	set $ref = $array->klass_.reference_
	set $mon = $array->monitor_
	set $len = $array->length_

	printf "reference_ = 0x%08x\n", $ref
	printf "monitor_ = 0x%08x\n", $mon
	printf "length = %d\n", $len

	set $i = 0
	while $i < $len
		printf "ele[%-2d] = 0x%08x\n", $i, $array->first_element_[$i]
		set $i++
	end
end


document pMirrorArray
	Prints Android art::mirror::Array information.
	Syntax: pMirrorArray <array>   array is the address of art::mirror::Array object
	Examples:
	pMirrorArray 0x6fb96850    - prints all information about art::mirror::Array at 0x6fb96850
end

#
# Print art::mirror::Class data structure.
#
define pMirrorClass
	set $class = ('art::mirror::Class' *)$arg0
	p /x *$class
	printf "Class name is following:\n"

	GetAndroidOS
	# For Android 7.0/7.1, uncompressed
	if $Android_OS == 'N'
		x/1sh (('art::mirror::String' *)$class->name_.reference_).value_
	end

	# For Android 8.0/8.1, compressed
	if $Android_OS == 'O'
		x/1sb (('art::mirror::String' *)$class->name_.reference_).value_
	end
end

document pMirrorClass
	Prints Android art::mirror::Class information.
	Syntax: pMirrorClass <class>   class is the address of art::mirror::Class object
	Examples:
	pMirrorClass 0x6f97c2a8    - prints all information about art::mirror::Class at 0x6f97c2a8
end

#
# Print art::mirror::String data structure.
#
define pMirrorString
	set $string = ('art::mirror::String' *)$arg0
	p /x *$string
	printf "String name is following:\n"
	GetAndroidOS

	# For Android 7.0/7.1, uncompressed
	if $Android_OS == 'N'
		x/1sh (('art::mirror::String' *)$class->name_.reference_).value_
	end

	# For Android 8.0/8.1, compressed
	if $Android_OS == 'O'
		x/1sb (('art::mirror::String' *)$class->name_.reference_).value_
	end
end

document pMirrorString
	Prints Android art::mirror::String information.
	Syntax: pMirrorString <string>   string is the address of art::mirror::String object
	Examples:
	pMirrorString 0x6f62b940    - prints all information about art::mirror::String at 0x6f62b940
end

define pIRT
	set $kind = $arg0 & 0x03

	GetAndroidOS
	if $Android_OS == 'N'
		set $jvm = 'art::Runtime::instance_'->java_vm_
		set $serial = ($arg0 >> 20) & 0x03
		set $idx = ($arg0 >> 2) & 0xffff
	end

	if $Android_OS == 'O'
		set $jvm = ('art::JavaVMExt' *)('art::Runtime::instance_'->java_vm_.__ptr_.__first_)
		set $serial = ($arg0 >> 2) & 0x03
		set $idx = $arg0 >> 4
	end

	# Local
	if $kind == 0x01
		printf "Not implemented\n"
	end

	# Global
	if $kind == 0x02
		set $table = $jvm->globals_.table_
		printf "The object for indirect reference(0x%x) is following:\n", $arg0
		p /x $table[$idx].references_[$serial].root_.reference_
	end

	# Weak Global
	if $kind == 0x03
		set $table = $jvm->weak_globals_.table_
		printf "The object for indirect reference(0x%x) is following:\n", $arg0
		p /x $table[$idx].references_[$serial].root_.reference_
	end
end

document pIRT
	Prints Android art::IndirectReferenceTable information.
	Syntax: pIRT <indirect_reference>   indirect_reference is the indirect reference of object.
	Examples:
	(gdb) p 'art::Runtime::instance_'->system_class_loader_
	$226 = (_jobject *) 0x1001ae
	pIRT 0x1001ae               - prints the object for 0x1001ae
end

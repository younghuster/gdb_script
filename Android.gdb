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

		if $arg0.__r_.__first_.__l.__size_ == 0
			printf "Null string\n"
		else

			printf "\"%s\"\n", $arg0.__r_.__first_.__l.__data_
		end
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

define getAndroidOS
	set $p = (unsigned char *)'art::ImageHeader::kImageVersion'
	set $image_version = ($p[0] - '0') * 100 + ($p[1] - '0') * 10 + ($p[2] - '0')

	set $Android_OS = 'K'

	# Android 5.0/5.1
	if ($image_version == 9) || ($image_version == 12)
		set $Android_OS = 'L'
	end

	# Android 6.0
	if $image_version == 17
		set $Android_OS = 'M'
	end

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
	getAndroidOS

	# Android L/M/N: JavaVMExt* java_vm_;
	if ($Android_OS == 'L') ||($Android_OS == 'M') || ($Android_OS == 'N')
		p /x *'art::Runtime::instance_'->java_vm_
	end

	# Android O: std::unique_ptr<JavaVMExt> java_vm_
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
# Print JniEntryPoints and QuickEntryPoints data structure.
#
define pEntryPoints
	set $head = &'art::Runtime::instance_'->thread_list_->list_
	set $current = $head->__end_.__next_
	set $pointer_size = sizeof($current)
	if $current != 0
		set $t = *('art::Thread' **)((unsigned long)$current + $pointer_size * 2)

		printf "JniEntryPoints:\n"
		p /x $t->tlsPtr_.jni_entrypoints

		printf "\nQuickEntryPoints:\n"
		p /x $t->tlsPtr_.quick_entrypoints
	end
end

#
# boot_class_path_string_ is a std::string data structure.
#
define pBootClassPathString
	pString 'art::Runtime::instance_'->boot_class_path_string_
end

#
# boot_image_spaces_ is a std::vector data structure.
#
define pBootImageSpace
	set $boot_image_spaces = 'art::Runtime::instance_'->heap_->boot_image_spaces_
	set $begin = $boot_image_spaces.__begin_
	set $size = $boot_image_spaces.__end_ - $begin

	if $argc == 0
		set $i = 0
		while $i < $size
			printf "elem[%-2u]: ", $i
			p $begin[$i]
			set $i++
		end
	end

	if $argc == 1
		set $i = $arg0
		if $i < 0 || $i > $size_max
			printf "idx is not in acceptable range: [0..%u].\n", $size_max
		else
			printf "elem[%u]: ", $i
			p /x *$begin[$i]
			printf "\n[image name]: "
			pString $begin[$i]->name_
			printf "[image begin]: 0x%x\n", $begin[$i]->begin_
		end
	end

end

document pBootImageSpace
	Prints Android ART boot image space information.
	Syntax: pBootImageSpace <idx>
	Note: idx must be in acceptable range [0..boot_image_spaces_.size() - 1].
	Examples:
	pBootImageSpace        - Prints all boot image space information
	pBootImageSpace 0      - Prints the first boot image space information
end

#
# Print the specified art::ImageHeader data structure.
#
define pImageHeader
	if $argc == 0
		help pImageHeader
	end

	if $argc == 1
		p /x *('art::ImageHeader' *)$arg0
	end
end


document pImageHeader
	Prints Android art::ImageHeader information.
	Syntax: pImageHeader <image_begin>   image_begin is the start address of image file.
	Examples:
	pImageHeader 0x6fb4a000    - prints all information about art::ImageHeader at 0x6fb4a000
end

#
# Print image_roots_ in the art::ImageHeader data structure.
#
define pImageRoots
	if $argc == 0
		help pImageRoots
		exit
	else
		set $image_roots = ('art::mirror::Array' *)$arg0
		printf "image_roots_: \n"
		pMirrorArray $image_roots

		set $i = 0
		while $i < $image_roots->length_
			printf "\nimage_roots_[%d]: \n", $i
			pMirrorArray $image_roots->first_element_[$i]
			set $i++
		end
	end
end


document pImageRoots
	Prints Android image_roots_ information.
	Syntax: pImageRoots <image_roots>   image_roots is the image roots address.
	Examples:
	pImageRoots 0x6fb4a000    - prints all information about image_roots_ at 0x6fb4a000
end

#
# regions_ is a std::unique_ptr<Region[]> data structure(From Android 8.0).
#
define pRegionSpace
	set $region_space = 'art::Runtime::instance_'->heap_->concurrent_copying_collector_->region_space_
	set $size = $region_space->num_regions_
	set $size_max = $size - 1
	set $regions = ('art::gc::space::RegionSpace::Region' *)$region_space->regions_.__ptr_.__first_

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
	set $idx = 0

	getAndroidOS

	# For Android 5.0/5.1/6.0, std::vector<GcRoot<mirror::DexCache>> dex_caches_
	if ($Android_OS == 'L') || ($Android_OS == 'M')
		set $begin = $head->__begin_
		set $size = $head->__end_ - $begin

		while $idx < $size
			set $dex_cache = ('art::mirror::DexCache' *)$begin[$idx].root_.reference_
			printf "DexFile location[%-2u]: ", $idx++
			pMirrorString $dex_cache->location_.reference_
		end
	end

	# For Android 7.0/7.1/8.0, std::list<DexCacheData> dex_caches_
	if ($Android_OS == 'N') || ($Android_OS == 'O')
		set $current = $head->__end_.__next_

		set $pointer_size = sizeof($current)
		while $current != $head
			set $dex = (('art::ClassLinker::DexCacheData' *)((unsigned long)$current + $pointer_size * 2))->dex_file
			printf "DexFile location[%-2u]: \"%s\"\n", $idx++, $dex->location_.__r_.__first_.__l.__data_
			set $current = $current->__next_
		end
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
	printf "\n[DexFile location]: \"%s\"\n", $dex->location_.__r_.__first_.__l.__data_
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

	printf "\nArtMethod information is following:\n"

	set $declaring_class = ('art::mirror::Class' *)$method->declaring_class_.root_.reference_
	set $dex_cache = ('art::mirror::DexCache' *)$declaring_class->dex_cache_.reference_
	set $dex_file = ('art::DexFile' *)$dex_cache->dex_file_
	printf "[dex file location]: \"%s\"\n", $dex_file->location_.__r_.__first_.__l.__data_

	printf "[class name]: "
	pMirrorString $declaring_class->name_.reference_

	set $dex_method_idx = $method->dex_method_index_
	printf "[dex method idx]: %d\n", $dex_method_idx

	#set $method_id = $dex_file->method_ids_[$dex_method_idx]
	#set $type_id = $dex_file->type_ids_[$method_id.class_idx_]
	#set $idx = $type_id.descriptor_idx_
	#set $string_id = $dex_file->string_ids_[idx]
	#set $ptr = $dex_file->begin_ + $string_id.string_data_off_
	#x/1sb $ptr
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

	set $idx = 0
	while $idx < $array->length_
		printf "ele[%-2d] = 0x%08x\n", $idx, $array->first_element_[$idx]
		set $idx++
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

	if $class->dex_cache_.reference_ != 0
		pMirrorDexCache $class->dex_cache_.reference_
	end

	printf "[class name]: "
	pMirrorString $class->name_.reference_

	set $super_class = ('art::mirror::Class' *)$class->super_class_.reference_
	if $super_class != 0
		printf "[super class name]: "
		pMirrorString $super_class->name_.reference_
	end
end

document pMirrorClass
	Prints Android art::mirror::Class information.
	Syntax: pMirrorClass <class>   class is the address of art::mirror::Class object
	Examples:
	pMirrorClass 0x6f97c2a8    - prints all information about art::mirror::Class at 0x6f97c2a8
end

#
# Print art::mirror::DexCache data structure.
#
define pMirrorDexCache
	set $dex_cache = ('art::mirror::DexCache' *)$arg0
	#p /x *$dex_cache
	printf "\n[DexFile location]: "
	pMirrorString $dex_cache->location_.reference_
end

document pMirrorDexCache
	Prints Android art::mirror::DexCache information.
	Syntax: pMirrorDexCache <dex_cache>   dex_cache is the address of art::mirror::DexCache object
	Examples:
	pMirrorDexCache 0x6f8cafe0    - prints all information about art::mirror::DexCache at 0x6f8cafe0
end

#
# Print art::mirror::String data structure.
#
define pMirrorString
	set $string = ('art::mirror::String' *)$arg0
	set $i = 0

	getAndroidOS

	# For Android 5.0/5.1, HeapReference<CharArray> array_;
	if $Android_OS == 'L'
		printf "Not implemented"
		exit
	end

	printf "\""
	# For Android 6.0/7.0/7.1, uncompressed
	if ($Android_OS == 'M') || ($Android_OS == 'N')
		while $i < $string->count_
			printf "%c", $string->value_[$i]
			set $i++
		end
	end

	# For Android 8.0/8.1, compressed
	if $Android_OS == 'O'
		set $count = $string->count_
		if $count & 0x01
			# uncompressed
			# TODO: to be verified.
			while $i < $count
				printf "%c", $string->value_[$i]
				set $i++
			end
		else
			# compressed
			set $count = $count >> 1
			set $p = (char *)$string->value_
			while $i < $count
				printf "%c", $p[$i]
				set $i++
			end
		end
	end
	printf "\"\n"
end

document pMirrorString
	Prints Android art::mirror::String information.
	Syntax: pMirrorString <string>   string is the address of art::mirror::String object
	Examples:
	pMirrorString 0x6f62b940    - prints all information about art::mirror::String at 0x6f62b940
end

define pIRT
	getAndroidOS

	if ($Android_OS == 'L')
		printf "Not implemented"
		exit
	end

	if ($Android_OS == 'M') || ($Android_OS == 'N')
		set $jvm = 'art::Runtime::instance_'->java_vm_
	end

	if $Android_OS == 'O'
		set $jvm = ('art::JavaVMExt' *)('art::Runtime::instance_'->java_vm_.__ptr_.__first_)
	end

	# Global/Weak Global/Local
	if $argc == 0
		# Global
		printf "Global indirect reference table is following:\n"
		p /x $jvm->globals_

		# Weak Global
		printf "\nWeak Global indirect reference table is following:\n"
		p /x $jvm->weak_globals_

		# Local
		printf "\nLocal indirect reference table is following:\n"
		set $head = &'art::Runtime::instance_'->thread_list_->list_
		set $current = $head->__end_.__next_
		set $pointer_size = sizeof($current)
		while $current != $head
			set $t = *('art::Thread' **)((unsigned long)$current + $pointer_size * 2)
			set $name = $t->tlsPtr_.name->__r_.__first_.__l.__data_
			printf "\nThread[tid = %-5d, name = %s]:\n", $t->tls32_.tid, $name,
			p /x $t->tlsPtr_.jni_env->locals
			set $current = $current->__next_
		end
	end

	# Global/Weak Global
	if $argc == 1
		set $kind = $arg0 & 0x03
		# Local
		if $kind == 0x01
			printf "Now you are checking the global/weak global reference instead of local reference.\n"

		else
			if $Android_OS == 'N'
				set $serial = ($arg0 >> 20) & 0x03
				set $idx = ($arg0 >> 2) & 0xffff
			end

			if $Android_OS == 'O'
				set $serial = ($arg0 >> 2) & 0x03
				set $idx = $arg0 >> 4
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
	end

	# Local
	if $argc == 2
		set $kind = $arg1 & 0x03
		if $kind != 1
			printf "Now you are checking the local reference instead of global/weak global reference.\n"
		else
			if $Android_OS == 'N'
				set $serial = ($arg1 >> 20) & 0x03
				set $idx = ($arg1 >> 2) & 0xffff
			end

			if $Android_OS == 'O'
				set $serial = ($arg1 >> 2) & 0x03
				set $idx = $arg1 >> 4
			end

			set $head = &'art::Runtime::instance_'->thread_list_->list_
			set $current = $head->__end_.__next_
			set $pointer_size = sizeof($current)
			while $current != $head
				set $t = *('art::Thread' **)((unsigned long)$current + $pointer_size * 2)
				if $arg0 == $t->tls32_.tid
					set $table = $t->tlsPtr_.jni_env->locals.table_
					set $name = $t->tlsPtr_.name->__r_.__first_.__l.__data_
					printf "Thread[tid = %-5d, name = %s]\n", $t->tls32_.tid, $name
					printf "The object for indirect reference(0x%x) is following:\n", $arg1
					p /x $table[$idx].references_[$serial].root_.reference_
					loop_break
				end
				set $current = $current->__next_
			end
		end
	end
end

document pIRT
	Prints Android art::IndirectReferenceTable information.
	Syntax: pIRT <indirect_reference>   indirect_reference is the indirect reference of object.
	Examples:
	(gdb) pIRT                              - Print Global/Weak Global/Local IRT information
	(gdb) pIRT <indirect reference>         - Print Global/Weak Global IRT information
	(gdb) pIRT <tid> <indirect reference>   - Print Local IRT information
end

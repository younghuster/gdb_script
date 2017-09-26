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
                #p /x $current
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
			if $argc == 2
				printf "elem[%-3u]: ", $size
				p *($arg1*)($current + 1)
			end
			if $argc == 3
				if $size == $arg2
					printf "elem[%u]: ", $size
					p *($arg1*)($current + 1)
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

#
# list_ is a std::list data structure.
#
define pThreadList
	set $head = &'art::Runtime::instance_'->thread_list_->list_
	#p /x $head

	set $current = $head->__end_.__next_
	#p /x $current

	set $pointer_size = sizeof(unsigned long)
	while $current != $head
		set $t = *('art::Thread' **)($current + 1)
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
# Print art::mirror::Array data structure.
#
define pArray
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


document pArray
	Prints Android art::mirror::Array information.
	Syntax: pArray <array>   array is the address of art::mirror::Array
	Examples:
	pArray 0x6fb96850    - prints all information about art::mirror::Array at 0x6fb96850
end


#
# java_vm_ is a JavaVMExt* data structure in art::Runtime.
#
define pJavaVMExt
	set $java_vm = ('art::JavaVMExt' *)('art::Runtime::instance_'->java_vm_.__ptr_.__first_)
	p /x *$java_vm
end

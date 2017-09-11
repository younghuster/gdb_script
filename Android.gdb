
#-------------------------------------------------------------
#                        Android libc++
#-------------------------------------------------------------
#
# std::list<>
#

define pList
	if $argc == 0
		help plist
	else
		set $head = &$arg0
		set $current = $arg0.__end_.__next_
                p /x $head
                p /x $current
		set $size = 0
		while $current != $head
                        set $data = *(unsigned int *)((unsigned int)$current + 8)
                        p /x $data
			if $argc == 2
				printf "elem[%u]: ", $size
				p *($arg1*)($data)
			end
			if $argc == 3
				if $size == $arg2
					printf "elem[%u]: ", $size
					p *($arg1*)($data)
				end
			end
                        set $current = *(unsigned int *)((unsigned int)$current + 4) 
			set $size++
		end
		printf "List size = %u \n", $size
		if $argc == 1
			printf "List "
			whatis $arg0
			printf "Use pList <variable_name> <element_type> to see the elements in the list.\n"
		end
	end
end

document plist
	Prints std::list<T> information.
	Syntax: pList <list> <T> <idx>: Prints list size, if T defined all elements or just element at idx
	Examples:
	pList 'art::Runtime::instance_'->thread_list_->list_                     - prints list size and definition
	pList 'art::Runtime::instance_'->thread_list_->list_  'art::Thread'      - prints all elements and list size
	pList 'art::Runtime::instance_'->thread_list_->list_  'art::Thread' 0    - prints the third element in the list (if exists) and list size
end

#-------------------------------------------------------------
#                        Android ART
#-------------------------------------------------------------

#
# Print thread list inforamtiion, such as tid, name and so on.
#
define pThreadList

  #set $list = 'art::Runtime::instance_'->thread_list_->list_
  #set $reg7 = &$list
  #set $reg6 = $list.__end_.__next_
  #p /x $list

  set $reg7 = &'art::Runtime::instance_'->thread_list_->list_
  #p /x $reg7

  set $reg6 = 'art::Runtime::instance_'->thread_list_->list_.__end_.__next_ 
  #p /x $reg6

  while $reg6 != $reg7
    set $t = ('art::Thread' *)(*(unsigned int *)((unsigned int)$reg6 + 8))
    #p /x $t
    set $name = *(unsigned int *)((unsigned int)$t->tlsPtr_.name + 8)
    printf "Thread[tid = %5d, name = %-40s]: flag = %d, state = %d\n", $t->tls32_.tid, $name, $t->tls32_.state_and_flags.as_struct.flags, $t->tls32_.state_and_flags.as_struct.state

    set $reg6 = *(unsigned int *)((unsigned int)$reg6 + 4) 
  end
end

#
# boot_image_spaces_ is a std::vector data structure
#
define pBootImageSpaces
  set $boot_image_spaces = &'art::Runtime::instance_'->heap_->boot_image_spaces_
  #printf "&boot_image_spaces_ = %x\n", $boot_image_spaces

  set $begin = *(unsigned int *)$boot_image_spaces
  #printf "begin = %x\n", $begin

  set $end = *(unsigned int *)((unsigned int)$boot_image_spaces + 4)
  #printf "end = %x\n", $end

  while $begin < $end
    set $space = *(unsigned int *)$begin
    p /x *('art::gc::space::ImageSpace' *)$space
    set $begin = *(unsigned int *)$begin + 4
  end
end

define pRegionSpace
  #set $num_regions_ = 'art::Runtime::instance_'->heap_->concurrent_copying_collector_->region_space_->num_regions_
  set $num_regions_ = 256
  set $regions_ = *(unsigned int *)&'art::Runtime::instance_'->heap_->concurrent_copying_collector_->region_space_->regions_
  set $i = 0

  while $i < $num_regions_
    set $region = $regions_ + $i * sizeof(art::gc::space::RegionSpace::Region)
    p *(art::gc::space::RegionSpace::Region *)$region
    set $i++
  end
end

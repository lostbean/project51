import React from 'react';
import {
  Menu,
  MenuButton,
  MenuList,
  MenuItem,
  Button,
  Avatar,
  Text,
  HStack,
  Box
} from '@chakra-ui/react';
import { FiUser, FiLogOut, FiChevronDown } from 'react-icons/fi';
import { useAuth } from '../auth/use-auth';

const UserMenu = () => {
  const { user, logout } = useAuth();
  
  if (!user) return null;
  
  return (
    <Menu>
      <MenuButton
        as={Button}
        variant="outline"
        rightIcon={<FiChevronDown />}
        borderColor="terminal.700"
        color="terminal.300"
        _hover={{ color: "terminal.200", borderColor: "terminal.600" }}
      >
        <HStack>
          <Avatar 
            size="xs" 
            name={user.name} 
            src={user.picture} 
            bg="terminal.700" 
            color="terminal.200"
            fontFamily="mono"
          />
          <Text fontFamily="mono" fontSize="sm">{user.name}</Text>
        </HStack>
      </MenuButton>
      <MenuList bg="area51.800" borderColor="terminal.700">
        <MenuItem 
          icon={<FiUser />} 
          bg="area51.800" 
          color="terminal.300"
          fontFamily="mono"
          _hover={{ bg: "area51.900", color: "terminal.200" }}
        >
          Profile
        </MenuItem>
        <MenuItem 
          icon={<FiLogOut />} 
          onClick={() => logout()}
          bg="area51.800" 
          color="terminal.300"
          fontFamily="mono"
          _hover={{ bg: "area51.900", color: "terminal.200" }}
        >
          Logout
        </MenuItem>
      </MenuList>
    </Menu>
  );
};

export default UserMenu;
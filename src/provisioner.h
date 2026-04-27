/*
Copyright (C) 2026  richardaburton@gmail.com 

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#ifndef __PROVISIONER_H
#define __PROVISIONER_H

#ifdef ENABLE_DOS_PROTECTION
#define RATE_LIMIT_TOKENS 16
#define RATE_LIMIT_WINDOW_NS 600000000000ULL // 10 minutes (600 seconds)

struct peer_quota {
    unsigned long long tokens;
    unsigned long long last_event_ts;
};
#endif // ENABLE_DOS_PROTECTION

struct record_t {
    unsigned char public_key[32];
    unsigned long long last_seen;
};

struct pk_wrap {
    unsigned char key[32];
};

struct event_t {
    unsigned char peer_id[32];
    unsigned __int128 new_ip;
};

struct scratch_pad {
    struct record_t record;
    struct event_t event;
    struct pk_wrap pk;
};

#endif // __PROVISIONER_H

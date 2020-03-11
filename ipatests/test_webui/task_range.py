# Authors:
#   Petr Vobornik <pvoborni@redhat.com>
#
# Copyright (C) 2013  Red Hat
# see file 'COPYING' for use and warranty information
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""
Range tasks
"""

import uuid

from ipatests.test_webui.ui_driver import UI_driver

LOCAL_ID_RANGE = 'ipa-local'
TRUSTED_ID_RANGE = 'ipa-ad-trust'


class range_tasks(UI_driver):

    BASE_RANGE_OVERLAPS_ERROR = (
        "Constraint violation: "
        "New base range overlaps with existing base range."
    )

    PRIMARY_RID_RANGE_OVERLAPS_ERROR = (
        "Constraint violation: "
        "New primary rid range overlaps with existing primary rid range."
    )

    SECONDARY_RID_RANGE_OVERLAPS_ERROR = (
        "Constraint violation: "
        "New secondary rid range overlaps with existing secondary rid range."
    )

    PRIMARY_AND_SECONDARY_RID_OVERLAP_ERROR = (
        "invalid 'ID Range setup': "
        "Primary RID range and secondary RID range cannot overlap"
    )

    DELETE_PRIMARY_LOCAL_RANGE_ERROR = (
        "invalid 'ipabaseid,ipaidrangesize': range modification "
        "leaving objects with ID out of the defined range is not allowed"
    )

    def get_shifts(self):
        result = self.execute_api_from_ui('idrange_find', [], {})
        idranges = result['result']['result']

        max_id = 0
        max_rid = 0

        for idrange in idranges:
            size = int(idrange['ipaidrangesize'][0])
            base_id = int(idrange['ipabaseid'][0])

            id_end = base_id + size
            rid_end = 0

            if 'ipabaserid' in idrange:
                base_rid = int(idrange['ipabaserid'][0])
                rid_end = base_rid + size

                if 'ipasecondarybaserid' in idrange:
                    secondary_base_rid = int(idrange['ipasecondarybaserid'][0])
                    rid_end = max(base_rid, secondary_base_rid) + size

            if max_id < id_end:
                max_id = id_end + 1000000

            if max_rid < rid_end:
                max_rid = rid_end + 1000000

        self.max_id = max_id
        self.max_rid = max_rid

    def get_domain(self):
        result = self.execute_api_from_ui('trust_find', [], {})
        trusts = result['result']['result']
        domain = None
        if trusts:
            domain = trusts[0]['cn']
        return domain

    def get_data(self, pkey=None, form_data=None, **kwargs):

        if not pkey:
            pkey = 'itest-range-{}'.format(uuid.uuid4().hex[:8])

        if form_data:
            form_data.cn = pkey
        else:
            form_data = self.get_add_form_data(pkey, **kwargs)

        data = {
            'pkey': pkey,
            'add': form_data.serialize(),
            'mod': [
                ('textbox', 'ipaidrangesize', str(form_data.size + 1)),
            ],
        }
        return data

    def get_add_form_data(self, pkey, range_type=LOCAL_ID_RANGE, size=50,
                          domain=None, **kwargs):
        """
        Generate RangeAddFormData instance with initial data based on existing
        ID ranges.
        :param kwargs: overrides default fields values (base_id, base_rid,
                       secondary_base_rid)
        """

        shift = 100
        base_id = kwargs.get('base_id', self.max_id + shift)
        self.max_id = base_id + size

        if 'base_rid' in kwargs:
            base_rid = kwargs['base_rid']
        else:
            base_rid = self.max_rid + shift
            self.max_rid = base_rid + size

        secondary_base_rid = None
        if not domain:
            if 'secondary_base_rid' in kwargs:
                secondary_base_rid = kwargs['secondary_base_rid']
            else:
                secondary_base_rid = self.max_rid + shift
                self.max_rid = secondary_base_rid + size

        return RangeAddFormData(
            pkey, base_id, base_rid,
            secondary_base_rid=secondary_base_rid,
            range_type=range_type,
            size=size,
            domain=domain,
            callback=self.check_range_type_mod
        )

    def get_mod_form_data(self, **kwargs):
        return RangeModifyFormData(**kwargs)

    def check_range_type_mod(self, range_type):
        if range_type == LOCAL_ID_RANGE:
            self.assert_disabled("[name=ipanttrusteddomainname]")
            self.assert_disabled("[name=ipasecondarybaserid]", negative=True)
        elif range_type == TRUSTED_ID_RANGE:
            self.assert_disabled("[name=ipanttrusteddomainname]",
                                 negative=True)
            self.assert_disabled("[name=ipasecondarybaserid]")


class RangeAddFormData:
    """
    Class for storing and serializing of new ID Range form data.

    Warning: Only for data transformation.
             Do not put any additional logic here!
    """

    def __init__(self, cn, base_id, base_rid=None, secondary_base_rid=None,
                 range_type=LOCAL_ID_RANGE, size=50, domain=None,
                 callback=None):
        self.cn = cn
        self.base_id = base_id
        self.base_rid = base_rid
        self.secondary_base_rid = secondary_base_rid
        self.range_type = range_type
        self.size = size
        self.domain = domain
        self.callback = callback

    def serialize(self):

        serialized = [
            ('textbox', 'cn', self.cn),
            ('textbox', 'ipabaseid', str(self.base_id)),
            ('textbox', 'ipaidrangesize', str(self.size)),
            ('textbox', 'ipabaserid', str(self.base_rid)),
            ('radio', 'iparangetype', self.range_type),
            ('callback', self.callback, self.range_type),
        ]

        if self.domain:
            serialized.append(('textbox',
                               'ipanttrusteddomainname',
                               self.domain))
        else:
            serialized.append(('textbox',
                               'ipasecondarybaserid',
                               str(self.secondary_base_rid)))

        return serialized


class RangeModifyFormData:
    """
    Class for storing and serializing of modified ID Range form data.
    """

    def __init__(self, base_id=None, base_rid=None, secondary_base_rid=None,
                 size=None):
        self.base_id = base_id
        self.base_rid = base_rid
        self.secondary_base_rid = secondary_base_rid
        self.size = size

    def serialize(self):
        serialized = []

        if self.base_id is not None:
            serialized.append(('textbox', 'ipabaseid', str(self.base_id)))
        if self.size is not None:
            serialized.append(('textbox', 'ipaidrangesize', str(self.size)))
        if self.base_rid is not None:
            serialized.append(('textbox', 'ipabaserid', str(self.base_rid)))
        if self.secondary_base_rid is not None:
            serialized.append(('textbox',
                               'ipasecondarybaserid',
                               str(self.secondary_base_rid)))

        return serialized

#!/bin/sh

#Check for needed tools
UTILS="sed tar awk cat mkdir tail mv more"
for util in ${UTILS}; do
    which ${util} > /dev/null 2>&1
    if [ $? != 0 ] ; then
cat <<EOF
********************************************************************************
Error: ${util} was not found in your path.
       ${util} is needed to run this installer.
       Please add ${util} to your path before running the installer again.
       Exiting installer.
********************************************************************************
EOF
       exit 1
    fi
done

#Verify that tar in path is GNU tar. If not, try using gtar.
#If gtar is not found, exit.
TAR=
tar --version > /dev/null 2>&1
if [ $? = 0 ] ; then
    TAR=tar
else
    which gtar > /dev/null 2>&1
    if [ $? = 0 ] ; then
        gtar --version > /dev/null 2>&1
        if [ $? = 0 ] ; then
            TAR=gtar
        fi
    fi
fi
if [ -z ${TAR} ] ; then
cat <<EOF
********************************************************************************
Error: GNU tar is needed to extract this installer.
       Please add it to your path before running the installer again.
       Exiting installer.
********************************************************************************
EOF
    exit 1
fi
platform="sles"
arch=x86_64
if [ -f /etc/SuSE-release ]; then
    if [ `uname -m` != "${arch}" ] ; then
        echo "Installer will only install on ${platform} ${arch}"
        exit 1
    fi
else
    echo "Installer will only install on ${platform} ${arch}"
    exit 1
fi
SKIP=`awk '/^__END_HEADER__/ {print NR + 1; exit 0; }' "$0"`

more << EOF

********************************************************************************
You must read and accept the Pivotal Database license agreement
before installing
********************************************************************************

       ***  IMPORTANT INFORMATION - PLEASE READ CAREFULLY  ***


PIVOTAL END USER LICENSE AGREEMENT AUGUST 2016 - CONFIDENTIAL

This End User License Agreement (“EULA”) is an agreement to license Software
between Licensee and Pivotal (meaning (a) Pivotal Software, Inc., if
Licensee is located in the United States; and (b) the local Pivotal sales
subsidiary, if Licensee is located in a country outside the United States in
which Pivotal has a local sales subsidiary; and (c) Pivotal Software
International (subject to Section 12 below), if Licensee is located in a
country outside the United States in which Pivotal does not have a local
sales subsidiary (in each case, referred to herein as “Pivotal”). Unless
otherwise set forth in a signed agreement between Pivotal (or its
Distributor) and Licensee, by downloading, installing or using Software,
Licensee is agreeing to these terms.

1. EVALUATION SOFTWARE AND BETA COMPONENTS.

If Licensee is licensing Software as Evaluation Software and/or as Beta
Components, then such use is solely for use in a non-production environment
for the Evaluation Period.  Notwithstanding any other provision in this
EULA, Evaluation Software and Beta Components are provided “AS-IS” without
indemnification, support, or warranty of any kind, expressed or implied. All
such licenses expire at the earlier of the end of the Evaluation Period or
upon return of the Evaluation Software.

2. GRANT AND USE RIGHTS FOR SOFTWARE.

  2.1. License Grant. The Software is licensed, not sold (nothing in this
  EULA shall be construed to mean that Pivotal has sold or otherwise
  transferred ownership of the Software).  Pivotal grants Licensee a
  non-exclusive, non-transferable license, without rights to sublicense, to
  use Software and Documentation, and related Support Services, up to the
  maximum licensed capacity during the period identified in the Quote, in
  the Territory, and subject to the Guide, for internal business operations
  only. Should Licensee exceed the licensed capacity, it will promptly
  procure additional license rights at a mutually agreed price.  Third Party
  Agents may access Software on Licensee’s behalf during the applicable
  period solely for Licensee’s internal business operations.  Licensee may
  make one (1) unmodified backup copy of Software solely for archival
  purposes. If Licensee upgrades or exchanges Software from a previous
  validly licensed version, Licensee must cease using all prior Software
  versions and certify same to Pivotal.  Licensee is responsible for
  obtaining any software, hardware or other technology required to operate
  Software and complying with any corresponding terms and conditions.

  2.2. License Restrictions. Licensee must not, and must not allow any third
  party to: (a) use Software in an application services provider, service
  bureau, or similar capacity; (b) disclose to any third party the results
  of any benchmark testing or comparative or competitive analyses of
  Software without Pivotal’s prior written approval; (c) except as otherwise
  expressly permitted by Pivotal, make Software available for access or use
  to any third party; (d) transfer or sublicense Software or Documentation
  (other than to an Affiliate, subject to Pivotal’s prior written approval);
  (e) use Software in conflict with the Guide, Quote and/or Order;
  (f) except as permitted by applicable mandatory law or third party
  license, modify, translate, enhance, or create derivative works from
  Software, or reverse assemble or disassemble, reverse engineer, decompile
  (subject to Section 2.5), or otherwise attempt to derive source code from
  Software; (g) remove any copyright or other proprietary notices on or in
  Software; or (h) violate or circumvent any technological restrictions
  within Software or as otherwise specified in this EULA.
  
  2.3. Open Source Software. OSS is licensed to Licensee under the
  applicable OSS license terms (a) located in the open_source_licenses.txt
  file included in or along with Software, Evaluation Software, or the
  corresponding source files available at network.pivotal.io/open-source,
  and/or (b) available by sending a written request, with Licensee’s name
  and address, to: Pivotal Software, Inc., Open Source Files Request, Attn:
  General Counsel, 875 Howard Street, 5th Floor, San Francisco, CA 94103.
  This offer to obtain a copy of the licenses/source files is valid for
  three (3) years from the date Licensee first acquired access to Software.
  Licensee is responsible for complying with all applicable OSS terms and
  conditions, which shall take precedence over this EULA, solely with
  respect to such OSS.  2.4. Subscription License. If a Quote or Order
  indicates a Subscription License which is subject to a non-cancelable and
  non-refundable fee), then the terms in this Section 2.4 shall also apply.
  At least sixty (60) days before expiration of the Subscription Period,
  Pivotal will notify Licensee of its option to renew for one (1) additional
  year at the same annual rate in the Quote or Order. Licensee’s
  Subscription License shall automatically renew at the end of the
  Subscription Period for one (1) additional year at the same annual rate
  stated in the Quote or Order if Licensee does not notify Pivotal at least
  thirty (30) days before expiration of the Subscription Period of
  Licensee’s intent not to renew. Upon such notification, Licensee agrees to
  cease using Software at the expiration of the Subscription Period and will
  certify cessation of use to Pivotal.
  
  2.5. Decompilation. If applicable laws in the Territory grant an express
  right to decompile Software to render it interoperable with other
  software, Licensee may decompile Software, but must first request Pivotal
  to do so, providing all requested information to allow Pivotal to assess
  the request.  Pivotal may, in its discretion, provide such
  interoperability information, impose reasonable conditions, including a
  reasonable fee, on such use of Software, or offer to provide alternatives
  to protect Pivotal’s proprietary rights therein.
  
  2.6. Reserved Rights. Pivotal retains all right, title, and interest in
  and to Software and Documentation, all related intellectual property
  rights, and all rights not expressly granted to Licensee in this EULA.

3. PURCHASING, DELIVERY AND PAYMENT.

  3.1 Purchasing. Each Licensee Order is subject to this EULA, and shall
  reference the applicable Pivotal Quote. No Orders are binding until
  accepted by Pivotal. Orders for Software are deemed accepted upon
  Pivotal’s delivery of Software included in such Order. Orders issued to
  Pivotal do not have to be signed to be valid and enforceable.  Licensee
  shall pay in full in accordance with Pivotal’s invoice.

  3.2 Delivery. Software shall be provided by electronic download and deemed
  to be delivered and accepted, meaning that Software operates in
  substantial conformity to the Documentation upon transmission of a notice
  of availability for download.
  
  3.3 Payment. Licensee shall pay Pivotal’s invoices for fees within thirty
  (30) days after the date of Pivotal’s invoice, with interest accruing
  thereafter at the lesser of one and one half percent (1.5%) per month or
  the highest lawful rate. In addition to the charges due hereunder,
  Licensee shall pay or reimburse to Pivotal for all valued added (VAT),
  sales, use, excise, withholding, personal property and other taxes
  resulting from a Licensee purchase order, except for taxes based on
  Pivotal’s net income. If Licensee is required to withhold taxes, then
  Licensee will forward any withholding receipts to Pivotal at
  legal@pivotal.io.

4. LIMITED WARRANTY.

  4.1 Software Warranty. Pivotal warrants to Licensee that Software will,
  for the Warranty Period, substantially conform to the applicable
  Documentation, provided such Software: (a) has been properly installed and
  used in accordance with the Documentation; and (b) has not been modified
  by persons other than Pivotal. For any breach of this warranty, Pivotal
  will, at its option and expense, and as Licensee’s exclusive remedy for
  any breach of this warranty, either replace that Software or correct any
  reproducible error in that Software reported to Pivotal by Licensee in
  writing during the Warranty Period. If Pivotal determines that it is
  unable to replace that Software or correct that error, Pivotal will refund
  to Licensee the amount paid by Licensee for that Software, and the license
  will terminate.

  4.2 Warranty Exclusions. EXCEPT AS SET FORTH IN SECTIONS 4.1 AND 4.2, AND
  TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, PIVOTAL AND ITS
  DISTRIBUTORS PROVIDE THE SOFTWARE WITHOUT ANY WARRANTIES OF ANY KIND,
  EXPRESS, IMPLIED, STATUTORY, OR IN ANY OTHER PROVISION OF THIS EULA OR
  COMMUNICATION WITH LICENSEE, AND PIVOTAL AND ITS DISTRIBUTORS SPECIFICALLY
  DISCLAIM ANY IMPLIED WARRANTIES OR CONDITIONS OF MERCHANTABILITY, FITNESS
  FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, TITLE, AND ANY WARRANTIES
  ARISING FROM COURSE OF DEALING OR COURSE OF PERFORMANCE REGARDING OR
  RELATING TO THE SOFTWARE, THE DOCUMENTATION, OR ANY MATERIALS FURNISHED OR
  PROVIDED TO LICENSEE UNDER THIS EULA. PIVOTAL AND ITS DISTRIBUTORS DO NOT
  WARRANT THAT THE SOFTWARE WILL OPERATE UNINTERRUPTED, OR THAT IT WILL BE
  FREE FROM DEFECTS OR THAT THE SOFTWARE WILL MEET (OR IS DESIGNED TO MEET)
  LICENSEE’S BUSINESS REQUIREMENTS.

5. IP INDEMNITY.

  5.1. IP Indemnity. Subject to the remainder of this Section 5 and Section
  6 of this EULA, Pivotal shall (a) defend Licensee against any Claim that
  Software infringes a copyright or patent enforceable in a Berne Convention
  signatory country; and (b) pay resulting costs and damages finally awarded
  against Licensee by a court of competent jurisdiction, or pay amounts
  stated in a written settlement negotiated and approved by Pivotal.

  5.2. Procedure and Remedies. The foregoing obligations apply only if
  Licensee: (a) promptly notifies Pivotal promptly in writing of such Claim;
  (b) grants Pivotal sole control over defense and settlement; (c)
  reasonably cooperates in response to Pivotal’s request for assistance; (d)
  is not in material breach of this EULA; and (e) is current in payment of
  all applicable fees prior to Claim. If the allegedly infringing Software
  is held to constitute an infringement, or in Pivotal’s opinion, any such
  Software is likely to become infringing and their use enjoined, Pivotal
  may, at its sole option and expense: (i) procure for Licensee the right to
  make continued use of the affected Software; (ii) replace or modify the
  affected Software to make it non-infringing; or (iii) notify Licensee to
  return the affected Software and, upon receipt, discontinue the related
  support services (if applicable) and, for Subscription Licenses, refund
  unused prepaid fees calculated based on each month remaining in the period
  identified in the Quote or Order.

  5.3. IP Indemnity Exclusions. Neither Pivotal nor any Distributor shall
  have any obligation under this Section 6 or otherwise with respect to any
  infringement Claim that arises out of or relates to: (a) combination,
  operation or use of the Software with any other software, hardware,
  technology, data, or other materials; (b) use for a purpose or in a manner
  for which Software was not designed or use after Pivotal notifies Licensee
  to cease such use due to a possible or pending infringement Claim; (c) any
  modifications Software made by any person other than Pivotal or its
  authorized representatives; (d) any modifications to Software made by
  Pivotal pursuant to instructions, designs, specifications, or any other
  information provided to Pivotal by or on behalf of Licensee; (e) use of
  any version of Software when an upgrade or a newer iteration of Software
  made available by Pivotal could have avoided the infringement; (f) any
  data or information which Licensee or a third party utilizes in connection
  with Software; or (g) any Open Source Software. THIS SECTION 5 STATES
  LICENSEE’S SOLE AND EXCLUSIVE REMEDY AND PIVOTAL’S ENTIRE LIABILITY FOR
  ANY INFRINGEMENT CLAIMS.

6. LIMITATION OF LIABILITY. TO THE MAXIMUM EXTENT MANDATED BY LAW, IN NO
EVENT SHALL PIVOTAL OR ITS DISTRIBUTORS BE LIABLE FOR ANY LOST PROFITS OR
BUSINESS OPPORTUNITIES, LOSS OF USE, LOSS OF REVENUE, LOSS OF GOODWILL,
BUSINESS INTERRUPTION, LOSS OF DATA, OR ANY OTHER INDIRECT, SPECIAL,
INCIDENTAL, OR CONSEQUENTIAL DAMAGES UNDER ANY THEORY OF LIABILITY, WHETHER
BASED IN CONTRACT, TORT, NEGLIGENCE, PRODUCT LIABILITY OR OTHERWISE.
PIVOTAL’S AND ITS DISTRIBUTORS’ LIABILITY UNDER THIS EULA SHALL NOT, IN ANY
EVENT, EXCEED THE LESSER OF (A) FEES LICENSEE PAID FOR SOFTWARE DURING THE
TWELVE (12) MONTHS PRECEDING THE DATE PIVOTAL RECEIVES WRITTEN NOTICE OF THE
FIRST CLAIM TO ARISE UNDER THIS EULA; OR (B) USD $1,000,000. THE FOREGOING
LIMITATIONS SHALL APPLY REGARDLESS OF WHETHER PIVOTAL OR ITS DISTRIBUTORS
HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF
WHETHER ANY REMEDY FAILS OF ITS ESSENTIAL PURPOSE. LICENSEE MAY NOT BRING A
CLAIM UNDER THIS EULA MORE THAN EIGHTEEN (18) MONTHS AFTER (i) THE END OF
THE SUBSCRIPTION PERIOD, FOR SUBSCRIPTION LICENSES, AND (ii) THE CLAIM FIRST
ARISES FOR ALL OTHER CLAIMS.

7. TERMINATION. Pivotal may terminate this EULA effective immediately upon
written notice to Licensee if: (a) Licensee fails to pay any portion of fees
due under an applicable Quote and/or Order within ten (10) days after
receiving notice that payment is past due; (b) Licensee suffers an
insolvency or analogous event; (c) Licensee commits a material breach of
this EULA that is incapable of being cured; or (d) Licensee breaches any
other provision of this EULA and does not cure the breach within thirty (30)
days after receiving written notice of breach. If the EULA expires or
terminates, Licensee must remove and destroy all copies of Software,
including all backup copies, from the server, virtual machine, and all
computers and terminals on which Software (including copies) is installed or
used and certify destruction thereof. Pivotal may also terminate this EULA
for convenience by giving three (3) month’s written notice to Licensee. All
provisions of this EULA will survive any termination or expiration if by its
nature and context it is intended to survive.

8. CONFIDENTIALITY. Each party shall (a) use the other party’s Confidential
Information only for exercising rights and performing obligations in
connection with this EULA; and (b) protect from disclosure any Confidential
Information disclosed by the other party for a period commencing upon the
disclosure date until 3 years thereafter. Notwithstanding the foregoing,
either party may disclose Confidential Information: (i) to an Affiliate to
fulfill its obligations or exercise its rights under this EULA so long as
such Affiliate agrees to comply with these restrictions in writing; and
(ii) if required by law or regulatory authorities provided the receiving
party has given the disclosing party prompt notice before disclosure.
Pivotal shall not be responsible for unauthorized disclosure of Licensee’s
data stored within Software arising from a data security breach. Licensee is
solely responsible for all obligations to comply with laws applicable to
Licensee’s Software use, including without limitation any personal data
processing. Pivotal may collect, use, store and transmit technical and
related information about Licensee’s Software use, including server internet
protocol address, hardware identification, operating system, application
software, peripheral hardware, and Software usage statistics, to facilitate
the provisioning of updates, support, invoicing, and online services.
Licensee is responsible for obtaining all consents required to enable
Pivotal to exercise its confidentiality rights, in compliance with
applicable law.

9. RECORDS/AUDIT. For the period set forth in the Quote and/or Order, any
renewals, and for three (3) years thereafter, Licensee shall maintain
accurate records regarding its compliance with this EULA. Upon reasonable
notice (and no more than once per year), Pivotal may audit Licensee’s
Software use to determine such compliance and payment of fees. Licensee will
promptly pay additional fees identified by the audit and reimburse Pivotal
for all audit costs if it discloses underpayment by more than five percent
(5%) in the audited period, or that Licensee breached any EULA term.

10. EXPORT AND TRADE COMPLIANCE. The Software and any technology delivered
in connection therewith may be subject to governmental restrictions on
exports from the U.S., restrictions on exports from other countries in which
such technology may be provided or located, disclosures of technology to
foreign persons, exports from abroad of derivative products thereof, and the
importation and/or use of such technology included therein outside of the
United States (collectively, "Export Laws"). Diversion contrary to Export
Laws is expressly prohibited. Licensee shall, at its sole expense, comply
with all Export Laws, including without limitation all licensing,
authorization, documentation and reporting requirements and Pivotal export
policies made available to Licensee by Pivotal. Licensee represents that it
is not a Restricted Party, which shall be deemed to include any person or
entity: (a) located in or a national of Cuba, Iran, North Korea, Sudan,
Syria, Crimea, or any other countries that may, from time to time, become
subject to sanctions or with which U.S. persons are generally prohibited
from engaging in financial transactions; (b) on any restricted party or
entity list maintained by any U.S. governmental agency; or (c) any person or
entity involved in an activity restricted by any U.S. government agency.
Certain information or technology may be subject to the International
Traffic in Arms Regulations and shall only be exported, transferred or
released to foreign nationals inside or outside the United States in
compliance with such regulations.

11. GENERAL. This EULA is governed by California law. Each Party hereby
expressly consents to the personal jurisdiction of either the California
courts or the United States District Courts located in the State of
California and agrees that any action relating to or arising out of this
EULA be instituted and prosecuted only in the Superior Court of the County
of San Francisco or the United States District Court for the Northern
District of California. The U.N. Convention on Contracts for the
International Sale of Goods does not apply. Both parties shall comply with
all applicable laws and regulations and diversion contrary to such laws is
expressly prohibited. Except to the extent expressly set forth to the
contrary in this EULA, this EULA is not intended to confer upon any person
other than the parties hereto any rights or remedies. The parties are
independent contractors. This EULA is the complete statement of the parties’
agreement with regard to the subject matter hereof and may be modified only
by written agreement. Licensee shall not assign or transfer any rights under
this EULA or delegate any of its duties hereunder, by operation of law or
otherwise, without Pivotal’s prior written consent, and any such action in
violation of this provision, is null and void, and of no force, and a breach
of this EULA. Pivotal may assign or transfer this EULA to any
successors-in-interest to all or substantially all of the business or assets
of Pivotal whether by merger, reorganization, asset sale or otherwise, or to
any Affiliates of Pivotal, and this EULA shall inure to the benefit of and
be binding upon the respective permitted successors and assigns. Pivotal may
use Pivotal Affiliates or other sufficiently qualified subcontractors to
provide Support Services, provided that Pivotal remains responsible for
performance thereof. If any part of this EULA, an Order, or a Quote is held
unenforceable, the validity of the remaining provisions shall not be
affected. In the event of conflict or inconsistency among the Guide, this
EULA and the Order, the following order of precedence shall apply: (a) the
Guide, (b) this EULA and (c) the Order.

12. COUNTRY SPECIFIC TERMS [INTERNATIONAL]. The terms in this Section 12
apply only when Pivotal means Pivotal Software International and for the
avoidance of doubt these terms below shall replace the terms in the EULA
above as specifically stated and all other terms shall remain unchanged:

  12.1. Section 4 (LIMITED WARRANTY). The last sentence of Section 4 shall
  be deleted and replaced with:

    EXCEPT AS EXPRESSLY STATED IN THE APPLICABLE WARRANTY SET FORTH IN THIS
    EULA, PIVOTAL (INCLUDING ITS SUPPLIERS) MAKES NO OTHER EXPRESS OR
    IMPLIED WARRANTIES, WRITTEN OR ORAL. INSOFAR AS PERMITTED UNDER
    APPLICABLE LAW, ALL OTHER WARRANTIES ARE SPECIFICALLY EXCLUDED,
    INCLUDING WARRANTIES ARISING BY STATUTE, COURSE OF DEALING OR USAGE OF
    TRADE.

  12.2. Section 6 (LIMITATION OF LIABILITY). The entire Section is deleted
  and replaced with:

    6. LIMITATION OF LIABILITY.

      6.1. In case of death or personal injury caused by Pivotal’s
      negligence, in case of Pivotal’s willful misconduct, fraud or gross
      negligence, and where a limitation of liability is not permissible
      under applicable mandatory law, Pivotal shall be liable according to
      statutory law.

      6.2. Subject always to subsection 6.A, the liability of Pivotal
      (including its suppliers) to the Licensee under or in connection with
      a Licensee’s Order, whether arising from negligent error or omission,
      breach of contract, or otherwise shall not exceed the lesser of (a)
      fees Licensee paid for the specific service (calculated on an annual
      basis, when applicable) or Software during the twelve (12) months
      preceding Pivotal’s notice of such claim; or (b) one million euros
      (€1,000,000).

      6.3. In no event shall Pivotal (including its suppliers) be liable to
      Licensee however that liability arises, for the following losses,
      whether direct, consequential, special, incidental, punitive or
      indirect: (a) loss of actual or anticipated revenue or profits, loss
      of use, loss of actual or anticipated savings, loss of or breach of
      contracts, loss of goodwill or reputation, loss of business
      opportunity, loss of business, wasted management time, cost of
      substitute services or facilities, loss of use of any software or
      data; and/or (b) indirect, consequential, exemplary or incidental or
      special loss or damage; and/or (c) damages, costs and/or expenses due
      to third party claims; and/or (d) loss or damage due to the Licensee’s
      failure to comply with obligations under this EULA, failure to do
      back-ups of data or any other matter under the control of the Licensee
      and in each case whether or not any such losses were direct, foreseen,
      foreseeable, known or otherwise, and whether or not that party was
      aware of the circumstances in which such losses could arise. For the
      purposes of this Section 6, the term “loss” shall include a partial
      loss, as well as a complete or total loss.

      6.4. The parties expressly agree that should any limitation or
      provision contained in this Section 6 be held to be invalid under any
      applicable statute or rule of law, it shall to that extent be deemed
      omitted, but if any party thereby becomes liable for loss or damage
      which would otherwise have been excluded such liability shall be
      subject to the other limitations and provisions set out in this
      Section 6.

      6.5. The parties expressly agree that any order for specific
      performance made in connection with this EULA in respect of Pivotal
      shall be subject to the financial limitations set out in sub-section
      6.B.

      6.6. Licensee waives the right to bring any claim arising out of or in
      connection with this EULA more than twenty-four (24) months after the
      date of the cause of action giving rise to such claim.

      6.7. LICENSEE OBLIGATIONS IN RESPECT OF PRESERVATION OF DATA. During
      the term of the EULA, the Licensee shall:

        (a) from a point in time prior to the point of failure, (i) make
        full and/or incremental backups of data which allow recovery in an
        application consistent form, and (ii) store such back-ups at an
        off-site location sufficiently distant to avoid being impacted by
        the event(s) (e.g. including but not limited to flood, fire, power
        loss, denial of access or air crash) and affect the availability of
        data at the impacted site;

        (b) have adequate processes and procedures in place to restore data
        back to a point in time and prior to point of failure, and in the
        event of real or perceived data loss, provide the skills/backup and
        outage windows to restore the data in question;

        (c) use anti-virus software, regularly install updates across all
        data which is accessible across the network, and protect all storage
        arrays against power surges and unplanned power outages with
        uninterruptible power supplies; and

        (d) ensure that all operating system, firmware, system utility (e.g.
        but not limited to, volume management, cluster management and
        backup) and patch levels are kept to Pivotal recommended versions
        and that any proposed changes thereto shall be communicated to
        Pivotal in a timely fashion.

  12.3. Section 10 (General) The first two sentences of Section 10 shall be
  deleted and replaced with:

    This EULA is governed by the laws of the Republic of Ireland, excluding
    its conflict of law rules. Each party hereby expressly consents to the
    personal jurisdiction of the Dublin Courts and agrees that any action
    relating to or arising out of this EULA be instituted and prosecuted
    only in the Dublin Courts.

13. DEFINITIONS.

  “Affiliate” means a legal entity controlled by, controls, or is under
  common control of Pivotal or Licensee, with “control” meaning more than
  fifty (50%) of the voting power or ownership interests then outstanding of
  that entity. 
  
  “Beta Component” means a Software component not yet generally available
  but included in the Software.
  
  “Claim(s)” means any third party claim, notice, demand, action,
  proceeding, litigation, investigation or judgment. With respect to
  Software, such Claim must be related to Licensee’s use of the Software
  during the Subscription Period (or renewal thereof).
  
  “Confidential Information” means the terms of this EULA, Software, and all
  confidential and proprietary information of Pivotal or Licensee, including
  without limitation, all business plans, product plans, financial
  information, software, designs, and technical, business and financial data
  of any nature whatsoever, provided that such information is marked or
  designated in writing as “confidential,” “proprietary,” or with a similar
  term or designation. Confidential Information does not include information
  that is (a) rightfully in the receiving party’s possession without prior
  obligation of confidentiality from the disclosing party; (b) a matter of
  public knowledge (or becomes a matter of public knowledge other than
  through breach of confidentiality by the other party); (c) rightfully
  furnished to the receiving party by a third party without confidentiality
  restriction; or (d) independently developed by the receiving party without
  reference to the disclosing party's Confidential Information.
  
  “Distributor” means a reseller, distributor, system integrator, service
  provider, independent software vendor, value-added reseller, OEM or other
  partner authorized by Pivotal to license Software to end users, and any
  third party duly authorized by a Distributor to license Software to end
  users.
  
  “Documentation” means documentation provided to Licensee by Pivotal with
  Software, as revised by Pivotal from time to time.
  
  “Evaluation Period” means ninety (90) days starting from delivery of the
  Evaluation Software or Beta Components.
  
  “Evaluation Software” means Software made available for the Evaluation
  Period at no charge, for Licensee’s evaluation purposes only (a) subject
  to a signed order; or (b) where Licensee has not signed a Quote.
  
  “Guide” means the Pivotal Product Guide available at
  http://www.pivotal.io/product-guide, in effect on the date of the Quote
  and incorporated into this EULA.
  
  “Licensee” means the person or the entity obtaining Software, and its
  permitted successors and assigns.
  
  “Major Release” means a generally available release of Software that
  Pivotal designates with a change in the digit to the left of the first
  decimal point (e.g., 5.0 >> 6.0).
  
  “Minor Release” means a generally available release of Software that
  Pivotal designated with a change in the digit to the right of the decimal
  point (e.g., 5.0 >> 5.1).
  
  “Open Source Software” or “OSS” means software components licensed under a
  license approved by the Open Source Initiative or similar open source or
  freeware license and included in, embedded in, utilized by, provided or
  distributed with Software.
  
  “Order” means a purchase order or other ordering document either signed by
  the parties or issued by Licensee to Pivotal or a Distributor that
  references and incorporates this EULA and is accepted by Pivotal as set
  forth in Section 3.
  
  “Perpetual License” means access to Software and Documentation subject to
  the licensing terms and restrictions set forth in the Guide on a perpetual
  basis.
  
  “Quote” means a pricing quote issued by Pivotal or its Distributor.
  
  “Software” means Pivotal computer programs listed in the Guide identified
  in a Quote, indicating a Perpetual License or Subscription License.
  
  “Subscription License” means (a) access to Software and Documentation
  subject to the licensing terms and restrictions set forth in the Guide;
  and (b) Support Services, which include any Minor and Major Releases and
  upgrades introduced with respect to the Subscription License set forth in
  the Quote on a “when and if available” basis, all during the Subscription
  Period.
  
  “Subscription Period” means the period starting upon notification to
  Licensee that Software is available for download, and continues for the
  period specified in the Quote.
  
  “Support Services” means services described at:
  http://www.pivotal.io/support.
  
  “Territory” means the country or countries in which Licensee has been
  invoiced.
  
  “Third Party Agent” means Licensee’s employees or contractors delivering
  information technology services to Licensee pursuant to a written contract
  requiring compliance with this EULA.
  
  “Warranty Period” means ninety (90) days following the first notice of
  availability of Software for download.


I HAVE READ AND AGREE TO THE TERMS OF THE ABOVE PIVOTAL SOFTWARE
LICENSE AGREEMENT.

EOF

agreed=
while [ -z "${agreed}" ] ; do
    cat << EOF

********************************************************************************
Do you accept the Pivotal Database license agreement? [yes|no]
********************************************************************************

EOF
    read reply leftover
        case $reply in
           [yY] | [yY][eE][sS])
                agreed=1
                ;;
           [nN] | [nN][oO])
                cat << EOF

********************************************************************************
You must accept the license agreement in order to install Greenplum Database
********************************************************************************
                             
                   **************************************** 
                   *          Exiting installer           *
                   **************************************** 

EOF
                exit 1
                ;;
        esac
done

installPath=/usr/local/greenplum-db-%%GP_VERSION%%
defaultinstallPath=${installPath}
user_specified_installPath=

while [ -z "${user_specified_installPath}" ] ; do
	cat <<-EOF
	
		********************************************************************************
		Provide the installation path for Greenplum Database or press ENTER to 
		accept the default installation path: $defaultinstallPath
		********************************************************************************
	
	EOF

    read user_specified_installPath leftover

    if [ -z "${user_specified_installPath}" ] ; then
        user_specified_installPath=${installPath}
    fi

    if [ -n "${leftover}" ] ; then
	    cat <<-EOF
			
			********************************************************************************
			WARNING: Spaces are not allowed in the installation path.  Please specify
			         an installation path without an embedded space.
			********************************************************************************
			
		EOF
        user_specified_installPath=
        continue
    fi

    pathVerification=
	while [ -z "${pathVerification}" ] ; do
	    cat <<-EOF
			
			********************************************************************************
			Install Greenplum Database into ${user_specified_installPath}? [yes|no]
			********************************************************************************
			
		EOF
	
	    read pathVerification leftover
	
	    case $pathVerification in
	        [yY] | [yY][eE][sS])
	            pathVerification=1
                installPath=${user_specified_installPath}
	            ;;
	        [nN] | [nN][oO])
	            user_specified_installPath=
	           ;;
	    esac
	done
done

if [ ! -d "${installPath}" ] ; then
    agreed=
    while [ -z "${agreed}" ] ; do
    cat << EOF

********************************************************************************
${installPath} does not exist.
Create ${installPath} ? [yes|no]
(Selecting no will exit the installer)
********************************************************************************

EOF
    read reply leftover
        case $reply in
           [yY] | [yY][eE][sS])
                agreed=1
                ;;
           [nN] | [nN][oO])
                cat << EOF

********************************************************************************
                             Exiting the installer
********************************************************************************

EOF
                exit 1
                ;;
        esac
    done
    mkdir -p ${installPath}
fi

if [ ! -w "${installPath}" ] ; then
    echo "${installPath} does not appear to be writeable for your user account."
    echo "Continue?"
    continue=
    while [ -z "${continue}" ] ; do
        read continue leftover
            case ${continue} in
                [yY] | [yY][eE][sS])
                    continue=1
                    ;;
                [nN] | [nN][oO])
                    echo "Exiting Greenplum Database installation."
                    exit 1
                    ;;
            esac
    done
fi

if [ ! -d ${installPath} ] ; then
    echo "Creating ${installPath}"
    mkdir -p ${installPath}
    if [ $? -ne "0" ] ; then
        echo "Error creating ${installPath}"
        exit 1
    fi
fi 


echo ""
echo "Extracting product to ${installPath}"
echo ""
tail -n +${SKIP} "$0" | ${TAR} zxf - -C ${installPath}
if [ $? -ne 0 ] ; then
    cat <<-EOF
********************************************************************************
********************************************************************************
                          Error in extracting Greenplum Database
                               Installation failed
********************************************************************************
********************************************************************************

EOF
    exit 1
fi

installDir=`basename ${installPath}`
symlinkPath=`dirname ${installPath}`
symlinkLink=greenplum-db
if [ x"${symlinkLink}" != x"${installDir}" ]; then
    if [ "`ls ${symlinkPath}/${symlinkLink} 2> /dev/null`" = "" ]; then
        ln -s "./${installDir}" "${symlinkPath}/${symlinkLink}"
    fi
fi
sed "s,^GPHOME.*,GPHOME=${installPath}," ${installPath}/greenplum_path.sh > ${installPath}/greenplum_path.sh.tmp
mv ${installPath}/greenplum_path.sh.tmp ${installPath}/greenplum_path.sh

    cat <<-EOF
********************************************************************************
Installation complete.
Greenplum Database is installed in ${installPath}

Pivotal Greenplum documentation is available
for download at http://gpdb.docs.pivotal.io
********************************************************************************
EOF

exit 0

__END_HEADER__

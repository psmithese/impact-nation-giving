class VisibilitySettings {
  final bool showMemberName;
  final bool showProfilePhoto;
  final bool showPledgeAmount;
  final bool showAmountPaid;
  final bool showOutstandingBalance;
  final bool showPaymentStatus;
  final bool showPaymentDate;
  final bool showPaymentHistory;
  final bool showDepartment;

  const VisibilitySettings({
    this.showMemberName = true,
    this.showProfilePhoto = true,
    this.showPledgeAmount = false,
    this.showAmountPaid = false,
    this.showOutstandingBalance = false,
    this.showPaymentStatus = true,
    this.showPaymentDate = true,
    this.showPaymentHistory = false,
    this.showDepartment = true,
  });

  factory VisibilitySettings.fromMap(Map<String, dynamic> map) {
    return VisibilitySettings(
      showMemberName: map['showMemberName'] as bool? ?? true,
      showProfilePhoto: map['showProfilePhoto'] as bool? ?? true,
      showPledgeAmount: map['showPledgeAmount'] as bool? ?? false,
      showAmountPaid: map['showAmountPaid'] as bool? ?? false,
      showOutstandingBalance: map['showOutstandingBalance'] as bool? ?? false,
      showPaymentStatus: map['showPaymentStatus'] as bool? ?? true,
      showPaymentDate: map['showPaymentDate'] as bool? ?? true,
      showPaymentHistory: map['showPaymentHistory'] as bool? ?? false,
      showDepartment: map['showDepartment'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showMemberName': showMemberName,
      'showProfilePhoto': showProfilePhoto,
      'showPledgeAmount': showPledgeAmount,
      'showAmountPaid': showAmountPaid,
      'showOutstandingBalance': showOutstandingBalance,
      'showPaymentStatus': showPaymentStatus,
      'showPaymentDate': showPaymentDate,
      'showPaymentHistory': showPaymentHistory,
      'showDepartment': showDepartment,
    };
  }

  VisibilitySettings copyWith({
    bool? showMemberName,
    bool? showProfilePhoto,
    bool? showPledgeAmount,
    bool? showAmountPaid,
    bool? showOutstandingBalance,
    bool? showPaymentStatus,
    bool? showPaymentDate,
    bool? showPaymentHistory,
    bool? showDepartment,
  }) {
    return VisibilitySettings(
      showMemberName: showMemberName ?? this.showMemberName,
      showProfilePhoto: showProfilePhoto ?? this.showProfilePhoto,
      showPledgeAmount: showPledgeAmount ?? this.showPledgeAmount,
      showAmountPaid: showAmountPaid ?? this.showAmountPaid,
      showOutstandingBalance: showOutstandingBalance ?? this.showOutstandingBalance,
      showPaymentStatus: showPaymentStatus ?? this.showPaymentStatus,
      showPaymentDate: showPaymentDate ?? this.showPaymentDate,
      showPaymentHistory: showPaymentHistory ?? this.showPaymentHistory,
      showDepartment: showDepartment ?? this.showDepartment,
    );
  }
}
